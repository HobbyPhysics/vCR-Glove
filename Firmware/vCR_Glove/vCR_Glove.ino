#include <bluefruit.h>
#include <math.h>
#include <nrf.h>

// ============================================================================
// DAEX_PAM8403_BLE_Tass_3to2_sinePWM_v6_double_shuffle
//
// Structural base:
//   DAEX_PAM8403_BLE_Tass_3to2_v1
//
// Signal-generation change:
//   Replaces the former 250 Hz narrow-pulse drive with a continuously running
//   64 kHz PWM/EasyDMA waveform. During a 100 ms burst, one channel's PWM duty
//   is sinusoidally modulated at the selected vibration frequency. All inactive channels remain at 50%
//   PWM duty, so every PAM8403 input has the carrier and only the selected
//   channel has the 250 Hz modulation.
//
// Existing PCB use before RC filters:
//   Scope each PAM input. The selected channel should show 64 kHz PWM with a
//   selected-frequency duty envelope for 100 ms. The other three inputs should show steady
//   50% PWM carrier.
// ============================================================================
//
// v6 changes:
//   1. Retains selectable single-frequency or four-frequency stimulation.
//   2. Single-frequency mode drives every burst at 250 Hz.
//   3. Multi-frequency mode now uses an independent "double shuffle":
//        - one random permutation chooses the four finger/channel locations;
//        - a second independent random permutation chooses the four frequencies.
//      Each 4-burst CR cycle therefore uses every finger once and every
//      frequency once, with no fixed finger-to-frequency association.
//   4. The multi-frequency set is:
//        207.65 Hz, 233.08 Hz, 277.18 Hz, 311.13 Hz.
//   5. Immediate repeats across permutation boundaries are prevented
//      independently for both finger order and frequency order.
//   6. Uses one nRF52840 hardware PWM peripheral per physical DAEX channel.
//      In multi-frequency mode an inactive channel is reconfigured just before
//      its burst for the frequency assigned by the frequency shuffle.
//   7. BLE START/READY/GO synchronization and the Tass 3:2 timing are unchanged.
//   8. MULTI_FREQUENCY_MODE is an experimental deviation from the
//      single-frequency Tass-style stimulation protocol; it has not been
//      clinically validated by this project.
//   9. LED_ENABLE may suppress burst-indicator flashing.
// ============================================================================

// ============================================================================
// USER CONFIGURATION
// Edit this section for normal setup changes. Values are arranged roughly from
// most likely to least likely to be changed by the user.
// ============================================================================

// ---------------- Hand identity ----------------
// 0 = right-hand unit
// 1 = left-hand unit
//
// The left-hand PCB connectors are physically ordered LRMI, so left-hand
// firmware always reverses the physical channel index. Logical channels 0..3
// therefore correspond to anatomical fingers IMRL on both hands.
#define IS_LEFT_HAND 0

// ---------------- Bilateral operation ----------------
// true  = both hands use the same shuffle sequence, so corresponding fingers
//         receive simultaneous bursts.
// false = both hands remain synchronized in time, but the left hand uses an
//         independent shuffle sequence. Finger selections between hands are
//         independent but simultaneous.
//
// This setting changes only the shuffle sequence. It does not alter the common
// jitter sequence or synchronized event timing.
const bool BILATERAL_MIRROR = true;

// ---------------- Stimulation protocol ----------------
// false = every burst uses SINGLE_FREQUENCY_HZ.
// true  = each 4-burst CR cycle independently shuffles both:
//         (1) the four logical finger channels and
//         (2) the four frequencies in MULTI_FREQUENCY_HZ[].
//         There is therefore no fixed finger-to-frequency assignment.
//
// IMPORTANT: MULTI_FREQUENCY_MODE is an experimental project option and is a
// significant deviation from the single-frequency Tass-style vCR protocol.
const bool MULTI_FREQUENCY_MODE = true;

const float SINGLE_FREQUENCY_HZ = 250.0f;  // allowed range: 60 to 350 Hz

const float MULTI_FREQUENCY_HZ[4] = {
  207.65f,  // G# below middle C
  233.08f,  // A# / Bb
  277.18f,  // C# / Db
  311.13f   // D# / Eb
};

const unsigned long PULSE_TIME_MS = 100;
const unsigned long DELAY_TIME_0_MS = 67;
const uint8_t ACTIVE_CR_COUNT = 3;
const uint8_t REST_CR_COUNT = 2;

// ---------------- Vibration amplitude ----------------
// Potentiometer endpoints map to these PWM sine-amplitude counts.
static constexpr int16_t MIN_AMPLITUDE_COUNTS = 2;
static constexpr int16_t MAX_AMPLITUDE_COUNTS = 50;

// ---------------- Jitter ----------------
// Set to 0.0f for no jitter. Tass noisy example: 0.235f.
const float JITTER_FRACTION = 0.235f;

// ---------------- BLE timing ----------------
const unsigned long SCAN_TIMEOUT_MS = 5000;
const unsigned long SYNC_DELAY_MS = 700;
const unsigned long ACK_TIMEOUT_MS = 250;
const uint8_t MAX_START_ATTEMPTS = 3;

// ---------------- Indicators ----------------
const bool LED_ENABLE = true;
const unsigned long LED_ON_TIME_MS = 100;

// ---------------- Deterministic random seeds ----------------
// The right hand always uses SHUFFLE_SEED_DEFAULT.
// In bilateral mirror mode, the left hand uses the same seed.
// In independent mode, the left hand uses SHUFFLE_SEED_INDEPENDENT.
const uint32_t SHUFFLE_SEED_DEFAULT = 123456UL;
const uint32_t SHUFFLE_SEED_INDEPENDENT = 654321UL;

// Frequency order uses a separate random stream so the frequency permutation is
// independent of the finger/channel permutation. Mirror mode uses the same
// frequency seed on both hands; independent bilateral mode uses a different
// left-hand seed.
const uint32_t FREQUENCY_SEED_DEFAULT = 314159UL;
const uint32_t FREQUENCY_SEED_INDEPENDENT = 271828UL;

// Jitter uses a separate common random stream, so changing shuffle correlation
// does not change jitter values or synchronized timing between hands.
const uint32_t COMMON_JITTER_SEED = 24681357UL;

// ============================================================================
// HARDWARE AND DERIVED CONSTANTS
// Normally do not edit below this line for routine configuration changes.
// ============================================================================

static constexpr uint8_t N_CH = 4;

// ---------------- Arduino pin assignments from the existing PCB ----------------
#define PIN_POT       A0
#define PIN_DAEX1     D1
#define PIN_DAEX2     D2
#define PIN_DAEX3     D3
#define PIN_DAEX4     D4
#define PIN_BUTTON    D5

#define PIN_LED1      D7
#define PIN_LED2      D8
#define PIN_LED3      D9
#define PIN_LED4      D10

#define PIN_PAM_SHDN  D6

// Direct nRF52840 GPIO numbers corresponding to XIAO silk D1-D4.
// PSEL uses 0..31 for Port 0 and 32..47 for Port 1.
static constexpr uint32_t DAEX_NRF_PSEL[N_CH] = {
  3,   // D1 = P0.03
  28,  // D2 = P0.28
  29,  // D3 = P0.29
  4    // D4 = P0.04
};

// ---------------- BLE ----------------
BLEUart bleuart;
BLEClientUart clientUart;

bool running = false;
bool startScheduled = false;
unsigned long startAtMs = 0;

bool lastButton = HIGH;
unsigned long lastDebounceMs = 0;

bool lookingForPeer = false;
unsigned long scanStartMs = 0;

bool awaitingReadyAck = false;
unsigned long readyWaitStartMs = 0;
uint8_t startRequestAttempts = 0;
uint16_t activeCentralConnHandle = 0xFFFFU;

// ---------------- Derived stimulation timing ----------------
const unsigned long PULSE_TIME_US = PULSE_TIME_MS * 1000UL;
const unsigned long DELAY_TIME_0_US = DELAY_TIME_0_MS * 1000UL;

const unsigned long CR_PERIOD_MS =
    N_CH * (PULSE_TIME_MS + DELAY_TIME_0_MS);          // 668 ms
const unsigned long CR_PERIOD_US = CR_PERIOD_MS * 1000UL;

const unsigned long REST_TIME_0_MS =
    REST_CR_COUNT * CR_PERIOD_MS;                      // 1336 ms
const unsigned long REST_TIME_0_US = REST_TIME_0_MS * 1000UL;

const int daexPhysicalPins[N_CH] = {
  PIN_DAEX1, PIN_DAEX2, PIN_DAEX3, PIN_DAEX4
};

const int ledPhysicalPins[N_CH] = {
  PIN_LED1, PIN_LED2, PIN_LED3, PIN_LED4
};

uint8_t channelOrder[N_CH];
uint8_t frequencyOrder[N_CH];

int8_t previousChannel = -1;
int8_t previousFrequencyIndex = -1;
uint32_t nextEventUs = 0;

// Separate deterministic random states for finger shuffle, frequency shuffle,
// and jitter.
uint32_t shuffleRngState = 1;
uint32_t frequencyRngState = 1;
uint32_t jitterRngState = 1;

// ---------------- PWM/EasyDMA sine generation ----------------
// Keep the tested PWM carrier fixed at 64 kHz so the existing two-pole RC
// reconstruction filters retain the same carrier rejection.
static constexpr uint32_t PWM_CLOCK_HZ = 16000000UL;
static constexpr uint32_t PWM_CARRIER_HZ = 64000UL;
static constexpr uint16_t PWM_TOP = PWM_CLOCK_HZ / PWM_CARRIER_HZ;  // 250
static constexpr uint16_t PWM_CENTER = PWM_TOP / 2U;                // 125

// Each physical DAEX channel uses its own nRF52840 PWM peripheral. This lets
// each channel have a different vibration frequency without changing protocol
// timing or interrupting the other channels' 64 kHz carriers.
NRF_PWM_Type * const PWM_INSTANCE[N_CH] = {
  NRF_PWM0,
  NRF_PWM1,
  NRF_PWM2,
  NRF_PWM3
};

// At startup, choose SINE_SAMPLES = 32..128 and
// R = PWM_REFRESH + 1 = 2..10 independently for each physical channel:
//
//   actual frequency = PWM_CARRIER_HZ / (SINE_SAMPLES * R)
//
// For requested frequencies from 60 to 300 Hz, this search normally gives an
// exact result or an error below about 0.6%.
static constexpr uint16_t MIN_SINE_SAMPLES = 32;
static constexpr uint16_t MAX_SINE_SAMPLES = 128;
static constexpr uint16_t MIN_SAMPLE_HOLD_R = 2;
static constexpr uint16_t MAX_SAMPLE_HOLD_R = 10;
static constexpr float MIN_VIBRATION_FREQUENCY_HZ = 60.0f;
static constexpr float MAX_VIBRATION_FREQUENCY_HZ = 350.0f;

struct PwmTiming {
  uint16_t sineSamples;
  uint16_t sampleHoldR;
  uint16_t pwmRefresh;
  float requestedFrequencyHz;
  float actualFrequencyHz;
};

PwmTiming pwmTimingPhysical[N_CH];
// Pot is sampled once at the start of each burst.
static constexpr uint16_t ADC_MAX = 4095;
static constexpr uint8_t POT_AVERAGE_SAMPLES = 8;

// Each PWM peripheral uses LOAD=Common and therefore needs one halfword per
// waveform step. A separate EasyDMA buffer is maintained for each physical
// DAEX channel.
static uint16_t pwmSequence[N_CH][MAX_SINE_SAMPLES]
    __attribute__((aligned(4)));

// ---------------- Utility ----------------
uint8_t physicalIndexForLogical(uint8_t logicalChannel) {
  // Physical connector order is IMRL on the right hand and LRMI on the left.
  // Reverse the left-hand physical index so logical channels 0..3 correspond
  // to anatomical fingers IMRL on both hands in both bilateral modes.
#if IS_LEFT_HAND
  return (N_CH - 1U) - logicalChannel;
#else
  return logicalChannel;
#endif
}

int ledPinForLogical(uint8_t logicalChannel) {
  return ledPhysicalPins[physicalIndexForLogical(logicalChannel)];
}

void allLedsOff() {
  for (uint8_t i = 0; i < N_CH; i++) {
    digitalWrite(ledPhysicalPins[i], LOW);
  }
}

uint16_t readPotentiometer() {
  uint32_t sum = 0;

  for (uint8_t i = 0; i < POT_AVERAGE_SAMPLES; i++) {
    sum += analogRead(PIN_POT);
  }

  return (uint16_t)(sum / POT_AVERAGE_SAMPLES);
}

int16_t potToAmplitude(uint16_t potReading) {
  if (potReading > ADC_MAX) potReading = ADC_MAX;

  const uint32_t amplitudeRange =
      (uint32_t)(MAX_AMPLITUDE_COUNTS - MIN_AMPLITUDE_COUNTS);

  const uint32_t scaled =
      (uint32_t)potReading * amplitudeRange;

  return (int16_t)(MIN_AMPLITUDE_COUNTS +
      ((scaled + ADC_MAX / 2U) / ADC_MAX));
}

void waitUntilUs(uint32_t targetUs) {
  while ((int32_t)(micros() - targetUs) < 0) {
    int32_t remainingUs = (int32_t)(targetUs - micros());

    if (remainingUs > 2000) {
      delay(1);
    } else if (remainingUs > 50) {
      delayMicroseconds((unsigned int)(remainingUs - 25));
    }
  }
}

void scheduleStart() {
  if (running || startScheduled) return;
  startAtMs = millis() + SYNC_DELAY_MS;
  startScheduled = true;
}

void stopBleActivity() {
  Bluefruit.Scanner.stop();
  Bluefruit.Advertising.restartOnDisconnect(false);
  Bluefruit.Advertising.stop();
  lookingForPeer = false;
}

uint32_t nextRandom32(uint32_t &state) {
  // xorshift32 cannot use a zero state.
  if (state == 0U) state = 0x6D2B79F5UL;

  uint32_t x = state;
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  state = x;
  return x;
}

uint32_t randomBelow(uint32_t &state, uint32_t upperExclusive) {
  if (upperExclusive == 0U) return 0U;
  return nextRandom32(state) % upperExclusive;
}

int32_t randomInclusive(
    uint32_t &state,
    int32_t lowerInclusive,
    int32_t upperInclusive) {
  if (upperInclusive <= lowerInclusive) return lowerInclusive;

  const uint32_t span =
      (uint32_t)((int64_t)upperInclusive - (int64_t)lowerInclusive + 1LL);

  return lowerInclusive +
      (int32_t)(nextRandom32(state) % span);
}

uint32_t selectedShuffleSeed() {
#if IS_LEFT_HAND
  // The left hand shares the default seed in mirror mode and uses a different
  // seed in non-mirror mode. Physical channel reversal is handled separately
  // by physicalIndexForLogical().
  return BILATERAL_MIRROR
      ? SHUFFLE_SEED_DEFAULT
      : SHUFFLE_SEED_INDEPENDENT;
#else
  // The right hand always uses the default seed.
  return SHUFFLE_SEED_DEFAULT;
#endif
}

uint32_t selectedFrequencySeed() {
#if IS_LEFT_HAND
  return BILATERAL_MIRROR
      ? FREQUENCY_SEED_DEFAULT
      : FREQUENCY_SEED_INDEPENDENT;
#else
  return FREQUENCY_SEED_DEFAULT;
#endif
}

void resetRandomSequence() {
  shuffleRngState = selectedShuffleSeed();
  frequencyRngState = selectedFrequencySeed();
  jitterRngState = COMMON_JITTER_SEED;

  for (uint8_t i = 0; i < N_CH; i++) {
    channelOrder[i] = i;
    frequencyOrder[i] = i;
  }

  previousChannel = -1;
  previousFrequencyIndex = -1;
}

void shuffleChannels() {
  for (int i = N_CH - 1; i > 0; i--) {
    int j = (int)randomBelow(shuffleRngState, (uint32_t)(i + 1));

    uint8_t temp = channelOrder[i];
    channelOrder[i] = channelOrder[j];
    channelOrder[j] = temp;
  }

  if (previousChannel >= 0 && channelOrder[0] == previousChannel) {
    uint8_t temp = channelOrder[0];
    channelOrder[0] = channelOrder[1];
    channelOrder[1] = temp;
  }
}

void shuffleFrequencies() {
  for (int i = N_CH - 1; i > 0; i--) {
    int j = (int)randomBelow(frequencyRngState, (uint32_t)(i + 1));

    uint8_t temp = frequencyOrder[i];
    frequencyOrder[i] = frequencyOrder[j];
    frequencyOrder[j] = temp;
  }

  if (previousFrequencyIndex >= 0 &&
      frequencyOrder[0] == previousFrequencyIndex) {
    uint8_t temp = frequencyOrder[0];
    frequencyOrder[0] = frequencyOrder[1];
    frequencyOrder[1] = temp;
  }
}

int32_t makeDelayJitterUs() {
  if (JITTER_FRACTION <= 0.0f) return 0;

  float requestedLimitUs =
      JITTER_FRACTION * ((float)CR_PERIOD_US / (2.0f * (float)N_CH));

  int32_t limitUs = (int32_t)(requestedLimitUs + 0.5f);
  if (limitUs < 1) return 0;

  return randomInclusive(jitterRngState, -limitUs, limitUs);
}

// Return the requested vibration frequency for one frequency-list index.
// In single-frequency mode the index is ignored.
float requestedFrequencyForIndex(uint8_t frequencyIndex) {
  if (!MULTI_FREQUENCY_MODE) {
    return SINGLE_FREQUENCY_HZ;
  }

  if (frequencyIndex >= N_CH) frequencyIndex = 0;
  return MULTI_FREQUENCY_HZ[frequencyIndex];
}

// Select the sine-table length and sample-hold count that produce the closest
// available vibration frequency while keeping the 64 kHz carrier fixed.
PwmTiming choosePwmTiming(float requestedHz) {
  float targetHz = requestedHz;

  if (targetHz < MIN_VIBRATION_FREQUENCY_HZ) {
    targetHz = MIN_VIBRATION_FREQUENCY_HZ;
  } else if (targetHz > MAX_VIBRATION_FREQUENCY_HZ) {
    targetHz = MAX_VIBRATION_FREQUENCY_HZ;
  }

  float bestErrorHz = 1.0e9f;
  uint16_t bestN = MIN_SINE_SAMPLES;
  uint16_t bestR = MIN_SAMPLE_HOLD_R;
  float bestActualHz = 0.0f;
  const float tieToleranceHz = 0.0001f;

  for (uint16_t n = MIN_SINE_SAMPLES; n <= MAX_SINE_SAMPLES; n++) {
    for (uint16_t r = MIN_SAMPLE_HOLD_R; r <= MAX_SAMPLE_HOLD_R; r++) {
      const float actualHz =
          (float)PWM_CARRIER_HZ / ((float)n * (float)r);
      const float errorHz = fabsf(actualHz - targetHz);

      if (errorHz < bestErrorHz - tieToleranceHz ||
          (fabsf(errorHz - bestErrorHz) <= tieToleranceHz && n > bestN)) {
        bestErrorHz = errorHz;
        bestN = n;
        bestR = r;
        bestActualHz = actualHz;
      }
    }
  }

  PwmTiming result;
  result.sineSamples = bestN;
  result.sampleHoldR = bestR;
  result.pwmRefresh = bestR - 1U;
  result.requestedFrequencyHz = requestedHz;
  result.actualFrequencyHz = bestActualHz;
  return result;
}

// Initialize every physical PWM output with the single-frequency timing.
// In multi-frequency mode, each inactive physical channel is reconfigured at
// burst time for the independently shuffled frequency assigned to that burst.
void selectAllPwmTimings() {
  Serial.println();
  Serial.print("Frequency mode: ");
  Serial.println(MULTI_FREQUENCY_MODE ? "MULTI - DOUBLE SHUFFLE" : "SINGLE");

  const PwmTiming initialTiming =
      choosePwmTiming(SINGLE_FREQUENCY_HZ);

  for (uint8_t physicalChannel = 0;
       physicalChannel < N_CH;
       physicalChannel++) {
    pwmTimingPhysical[physicalChannel] = initialTiming;
  }

  if (!MULTI_FREQUENCY_MODE) {
    Serial.print("  Requested ");
    Serial.print(initialTiming.requestedFrequencyHz, 3);
    Serial.print(" Hz, actual ");
    Serial.print(initialTiming.actualFrequencyHz, 3);
    Serial.print(" Hz, error ");
    Serial.print(
        initialTiming.actualFrequencyHz -
        initialTiming.requestedFrequencyHz,
        3);
    Serial.print(" Hz, N=");
    Serial.print(initialTiming.sineSamples);
    Serial.print(", R=");
    Serial.println(initialTiming.sampleHoldR);
    return;
  }

  Serial.println("  Available shuffled frequencies:");
  for (uint8_t frequencyIndex = 0;
       frequencyIndex < N_CH;
       frequencyIndex++) {
    const PwmTiming timing =
        choosePwmTiming(MULTI_FREQUENCY_HZ[frequencyIndex]);

    Serial.print("    F");
    Serial.print(frequencyIndex);
    Serial.print(": requested ");
    Serial.print(timing.requestedFrequencyHz, 3);
    Serial.print(" Hz, actual ");
    Serial.print(timing.actualFrequencyHz, 3);
    Serial.print(" Hz, error ");
    Serial.print(
        timing.actualFrequencyHz - timing.requestedFrequencyHz,
        3);
    Serial.print(" Hz, N=");
    Serial.print(timing.sineSamples);
    Serial.print(", R=");
    Serial.println(timing.sampleHoldR);
  }
}

// ---------------- PWM table construction ----------------
void buildQuietSequencePhysical(uint8_t physicalChannel) {
  const uint16_t n =
      pwmTimingPhysical[physicalChannel].sineSamples;

  for (uint16_t sample = 0; sample < n; sample++) {
    pwmSequence[physicalChannel][sample] = PWM_CENTER;
  }
}

void buildAllQuietSequences() {
  for (uint8_t physicalChannel = 0;
       physicalChannel < N_CH;
       physicalChannel++) {
    buildQuietSequencePhysical(physicalChannel);
  }
}

void buildBurstSequence(uint8_t logicalChannel, int16_t amplitudeCounts) {
  const uint8_t activePhysicalChannel =
      physicalIndexForLogical(logicalChannel);

  const uint16_t n =
      pwmTimingPhysical[activePhysicalChannel].sineSamples;

  for (uint16_t sample = 0; sample < n; sample++) {
    const float phase =
        2.0f * PI * (float)sample / (float)n;

    int32_t compareValue =
        (int32_t)PWM_CENTER +
        (int32_t)lroundf((float)amplitudeCounts * sinf(phase));

    if (compareValue < 0) compareValue = 0;
    if (compareValue > PWM_TOP) compareValue = PWM_TOP;

    pwmSequence[activePhysicalChannel][sample] =
        (uint16_t)compareValue;
  }
}

void configureAndStartOnePWM(uint8_t physicalChannel) {
  NRF_PWM_Type *pwm = PWM_INSTANCE[physicalChannel];
  const PwmTiming &timing =
      pwmTimingPhysical[physicalChannel];

  pwm->ENABLE = PWM_ENABLE_ENABLE_Disabled;

  const uint32_t psel = DAEX_NRF_PSEL[physicalChannel];
  const uint32_t port = psel / 32U;
  const uint32_t pin = psel % 32U;
  NRF_GPIO_Type *gpio = (port == 0U) ? NRF_P0 : NRF_P1;

  gpio->OUTCLR = (1UL << pin);
  gpio->PIN_CNF[pin] =
      (GPIO_PIN_CNF_DIR_Output << GPIO_PIN_CNF_DIR_Pos) |
      (GPIO_PIN_CNF_INPUT_Disconnect << GPIO_PIN_CNF_INPUT_Pos) |
      (GPIO_PIN_CNF_PULL_Disabled << GPIO_PIN_CNF_PULL_Pos) |
      (GPIO_PIN_CNF_DRIVE_S0S1 << GPIO_PIN_CNF_DRIVE_Pos) |
      (GPIO_PIN_CNF_SENSE_Disabled << GPIO_PIN_CNF_SENSE_Pos);

  // Each PWM peripheral uses only OUT[0].
  pwm->PSEL.OUT[0] =
      (pin << PWM_PSEL_OUT_PIN_Pos) |
      (port << PWM_PSEL_OUT_PORT_Pos) |
      (PWM_PSEL_OUT_CONNECT_Connected << PWM_PSEL_OUT_CONNECT_Pos);

  for (uint8_t out = 1; out < 4; out++) {
    pwm->PSEL.OUT[out] =
        PWM_PSEL_OUT_CONNECT_Disconnected << PWM_PSEL_OUT_CONNECT_Pos;
  }

  pwm->MODE =
      PWM_MODE_UPDOWN_Up << PWM_MODE_UPDOWN_Pos;

  pwm->PRESCALER =
      PWM_PRESCALER_PRESCALER_DIV_1 << PWM_PRESCALER_PRESCALER_Pos;

  pwm->COUNTERTOP =
      PWM_TOP << PWM_COUNTERTOP_COUNTERTOP_Pos;

  // LOAD=Common because this PWM peripheral drives only one physical output.
  pwm->DECODER =
      (PWM_DECODER_LOAD_Common << PWM_DECODER_LOAD_Pos) |
      (PWM_DECODER_MODE_RefreshCount << PWM_DECODER_MODE_Pos);

  pwm->SEQ[1].PTR =
      (uint32_t)pwmSequence[physicalChannel];
  pwm->SEQ[1].CNT =
      timing.sineSamples << PWM_SEQ_CNT_CNT_Pos;
  pwm->SEQ[1].REFRESH =
      timing.pwmRefresh << PWM_SEQ_REFRESH_CNT_Pos;
  pwm->SEQ[1].ENDDELAY = 0;

  pwm->LOOP = 1UL << PWM_LOOP_CNT_Pos;
  pwm->SHORTS = PWM_SHORTS_LOOPSDONE_SEQSTART1_Msk;

  pwm->EVENTS_LOOPSDONE = 0;
  pwm->EVENTS_SEQSTARTED[1] = 0;

  pwm->ENABLE = PWM_ENABLE_ENABLE_Enabled;
  pwm->TASKS_SEQSTART[1] = 1;
}

void configureAndStartAllPWM() {
  for (uint8_t physicalChannel = 0;
       physicalChannel < N_CH;
       physicalChannel++) {
    configureAndStartOnePWM(physicalChannel);
  }
}

// Reconfigure one currently inactive physical output for the frequency selected
// for the next burst. The 64 kHz PWM carrier remains unchanged; only the sine
// table length and sample-hold count are changed.
void setBurstFrequency(uint8_t logicalChannel, uint8_t frequencyIndex) {
  if (!MULTI_FREQUENCY_MODE) return;

  const uint8_t physicalChannel =
      physicalIndexForLogical(logicalChannel);

  pwmTimingPhysical[physicalChannel] =
      choosePwmTiming(requestedFrequencyForIndex(frequencyIndex));

  // Keep the output quiet while changing the PWM sequence timing.
  buildQuietSequencePhysical(physicalChannel);
  configureAndStartOnePWM(physicalChannel);
}

// ---------------- DAEX sine burst ----------------

inline void burstLedOn(int pin)
{
  if (LED_ENABLE) digitalWrite(pin, HIGH);
}

inline void burstLedOff(int pin)
{
  digitalWrite(pin, LOW);
}

void playBurst(
    uint8_t logicalChannel,
    uint8_t frequencyIndex,
    int ledPin) {

  const uint16_t potReading = readPotentiometer();
  const int16_t amplitudeCounts = potToAmplitude(potReading);

  // The selected physical channel was reconfigured, while still quiet,
  // before the scheduled burst start in runProtocolBlock().
  buildBurstSequence(logicalChannel, amplitudeCounts);

  burstLedOn(ledPin);

  // The protocol timeline already points to the intended burst start.
  // Keep the sine table active until the exact scheduled burst end.
  waitUntilUs(nextEventUs + PULSE_TIME_US);

  buildQuietSequencePhysical(physicalIndexForLogical(logicalChannel));
  burstLedOff(ledPin);
}

// Run one complete 3:2 block.
void runProtocolBlock() {
  int32_t blockJitterSumUs = 0;

  for (uint8_t crIndex = 0; crIndex < ACTIVE_CR_COUNT; crIndex++) {
    shuffleChannels();

    if (MULTI_FREQUENCY_MODE) {
      shuffleFrequencies();
    }

    for (uint8_t orderIndex = 0; orderIndex < N_CH; orderIndex++) {
      const uint8_t logicalChannel = channelOrder[orderIndex];

      // In single-frequency mode the frequency index is ignored.
      const uint8_t frequencyIndex =
          MULTI_FREQUENCY_MODE ? frequencyOrder[orderIndex] : 0U;

      // Reconfigure the next selected physical output during the inter-burst
      // quiet interval. This keeps frequency-switching overhead outside the
      // scheduled 100 ms burst.
      setBurstFrequency(logicalChannel, frequencyIndex);

      waitUntilUs(nextEventUs);

      playBurst(
          logicalChannel,
          frequencyIndex,
          ledPinForLogical(logicalChannel));

      nextEventUs += PULSE_TIME_US;

      int32_t jitterUs = makeDelayJitterUs();
      int32_t actualDelayUs = (int32_t)DELAY_TIME_0_US + jitterUs;

      if (actualDelayUs < 0) {
        // A delay cannot be negative. Clamp it to zero, and also clamp the
        // recorded jitter to the amount actually applied so rest-time
        // compensation preserves the intended total block duration.
        actualDelayUs = 0;
        jitterUs = -(int32_t)DELAY_TIME_0_US;
      }

      nextEventUs += (uint32_t)actualDelayUs;
      blockJitterSumUs += jitterUs;

      previousChannel = logicalChannel;
      if (MULTI_FREQUENCY_MODE) {
        previousFrequencyIndex = frequencyIndex;
      }
    }
  }

  int32_t actualRestUs =
      (int32_t)REST_TIME_0_US - blockJitterSumUs;

  if (actualRestUs < 0) actualRestUs = 0;

  nextEventUs += (uint32_t)actualRestUs;
}

void updateHaptics() {
  if (startScheduled && (int32_t)(millis() - startAtMs) >= 0) {
    startScheduled = false;

    stopBleActivity();

    // The initiating unit kept the BLE connection alive long enough for GO to
    // be delivered. Disconnect it now that both units have reached start time.
    if (activeCentralConnHandle != 0xFFFFU) {
      Bluefruit.disconnect(activeCentralConnHandle);
      activeCentralConnHandle = 0xFFFFU;
    }

    digitalWrite(PIN_PAM_SHDN, HIGH);
    delayMicroseconds(500);

    buildAllQuietSequences();
    allLedsOff();

    resetRandomSequence();
    nextEventUs = micros();
    running = true;
  }

  if (!running) {
    allLedsOff();
    return;
  }

  runProtocolBlock();
}

// ---------------- BLE ----------------
void startAdv() {
  Bluefruit.Advertising.stop();
  Bluefruit.Advertising.clearData();
  Bluefruit.ScanResponse.clearData();

  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(bleuart);
  Bluefruit.ScanResponse.addName();

  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);
}

void resumePeerScan() {
  if (!lookingForPeer) return;
  Bluefruit.Scanner.stop();
  Bluefruit.Scanner.start(0);
}

void scan_callback(ble_gap_evt_adv_report_t* report) {
  if (!lookingForPeer || awaitingReadyAck) {
    Bluefruit.Scanner.resume();
    return;
  }

  if (Bluefruit.Scanner.checkReportForService(report, clientUart)) {
    Bluefruit.Scanner.stop();

    if (!Bluefruit.Central.connect(report)) {
      // Keep the original overall five-second search window.
      resumePeerScan();
    }
  } else {
    Bluefruit.Scanner.resume();
  }
}

void sendStartRequest() {
  if (!clientUart.discovered()) return;

  // START asks the peer to confirm that it is present and ready.
  clientUart.write("S\n", 2);
  awaitingReadyAck = true;
  readyWaitStartMs = millis();
  startRequestAttempts++;
}

void connect_callback(uint16_t conn_handle) {
  activeCentralConnHandle = conn_handle;

  if (!clientUart.discover(conn_handle)) {
    // Service discovery failed. Disconnect and continue the same search window.
    Bluefruit.disconnect(conn_handle);
    awaitingReadyAck = false;
    return;
  }

  // The peripheral sends READY through the UART TX characteristic as a BLE
  // notification. The central must subscribe before it can receive READY.
  if (!clientUart.enableTXD()) {
    Bluefruit.disconnect(conn_handle);
    awaitingReadyAck = false;
    return;
  }

  sendStartRequest();
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason) {
  (void) reason;

  awaitingReadyAck = false;
  if (conn_handle == activeCentralConnHandle) {
    activeCentralConnHandle = 0xFFFFU;
  }

  if (lookingForPeer && !startScheduled && !running) {
    resumePeerScan();
  }
}

void beginPeerSearch() {
  if (running || startScheduled) return;
  if (lookingForPeer) return;

  lookingForPeer = true;
  awaitingReadyAck = false;
  startRequestAttempts = 0;
  scanStartMs = millis();

  Bluefruit.Scanner.stop();
  Bluefruit.Scanner.clearFilters();
  Bluefruit.Scanner.setRxCallback(scan_callback);
  Bluefruit.Scanner.restartOnDisconnect(false);
  Bluefruit.Scanner.setInterval(160, 80);
  Bluefruit.Scanner.useActiveScan(false);
  Bluefruit.Scanner.start(0);
}

// Peripheral/server side of the START/READY/GO handshake.
// S = START request: confirm presence by replying READY; do not schedule yet.
// G = GO command: schedule the synchronized start now.
void checkIncomingUart() {
  while (bleuart.available()) {
    char c = bleuart.read();

    if (c == 'S') {
      // Confirm that this unit is present and ready, but do not schedule until
      // the initiating unit sends GO.
      Bluefruit.Advertising.restartOnDisconnect(false);
      bleuart.write("A\n", 2);  // A = READY acknowledgment
    } else if (c == 'G') {
      // Both units have now confirmed the connection. GO is the common race
      // start signal. Each unit schedules from its local receipt/send time.
      scheduleStart();
      Bluefruit.Advertising.restartOnDisconnect(false);
    }
  }
}

// Central/client side of the handshake.
// After READY is received, send GO and schedule this unit immediately from the
// same event. The BLE connection is deliberately kept alive until the scheduled
// start so the queued GO notification has ample time to reach the peer.
void checkIncomingClientUart() {
  while (clientUart.available()) {
    char c = clientUart.read();

    if (c == 'A' && awaitingReadyAck) {
      awaitingReadyAck = false;

      clientUart.write("G\n", 2);  // G = GO
      scheduleStart();

      // Stop searching/advertising, but retain the established connection
      // until updateHaptics() reaches the scheduled start time.
      stopBleActivity();
    }
  }
}

void serviceReadyTimeout() {
  if (!awaitingReadyAck) return;
  if ((millis() - readyWaitStartMs) <= ACK_TIMEOUT_MS) return;

  awaitingReadyAck = false;

  if (startRequestAttempts < MAX_START_ATTEMPTS && clientUart.discovered()) {
    sendStartRequest();
    return;
  }

  // The START/READY handshake did not complete. Disconnect and continue
  // searching until the original SCAN_TIMEOUT_MS expires.
  if (activeCentralConnHandle != 0xFFFFU) {
    Bluefruit.disconnect(activeCentralConnHandle);
  } else {
    resumePeerScan();
  }
}

// ---------------- Button ----------------
void checkButton() {
  bool b = digitalRead(PIN_BUTTON);

  if (b != lastButton) {
    lastDebounceMs = millis();
    lastButton = b;
  }

  if ((millis() - lastDebounceMs) > 40) {
    static bool handledPress = false;

    if (b == LOW && !handledPress) {
      handledPress = true;
      beginPeerSearch();
    }

    if (b == HIGH) {
      handledPress = false;
    }
  }
}

// ---------------- Setup / Loop ----------------
void setup() {
  Serial.begin(115200);

  pinMode(PIN_BUTTON, INPUT_PULLUP);

  pinMode(PIN_PAM_SHDN, OUTPUT);
  digitalWrite(PIN_PAM_SHDN, LOW);   // PAM8403s disabled while waiting

  for (uint8_t i = 0; i < N_CH; i++) {
    pinMode(ledPhysicalPins[i], OUTPUT);
    digitalWrite(ledPhysicalPins[i], LOW);
  }

  analogReadResolution(12);
  pinMode(PIN_POT, INPUT);

  // Select the closest available sine timing, then start the four PWM
  // carriers immediately. PAM shutdown remains LOW.
  selectAllPwmTimings();
  buildAllQuietSequences();
  configureAndStartAllPWM();

  Bluefruit.begin(1, 1);
  Bluefruit.setTxPower(4);
  Bluefruit.setName("DAEX_v1");

  Bluefruit.Central.setConnectCallback(connect_callback);
  Bluefruit.Central.setDisconnectCallback(disconnect_callback);

  bleuart.begin();
  clientUart.begin();

  startAdv();
}

void loop() {
  if (!running) {
    checkIncomingUart();
    checkIncomingClientUart();
    serviceReadyTimeout();
    checkButton();

    if (lookingForPeer && (millis() - scanStartMs > SCAN_TIMEOUT_MS)) {
      // No usable peer handshake was completed. Stop all BLE activity and
      // commit to local-only operation. A late peer cannot join this session;
      // both units must be power-cycled to restore bilateral synchronization.
      stopBleActivity();
      awaitingReadyAck = false;

      if (activeCentralConnHandle != 0xFFFFU) {
        Bluefruit.disconnect(activeCentralConnHandle);
      }

      scheduleStart();
    }
  }

  updateHaptics();
}
