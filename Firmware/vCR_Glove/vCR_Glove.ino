/*
  DAEX_filtered_PWM_volume_burst_v1.ino

  Seeed Studio XIAO nRF52840

  Connections:
    XIAO silk D0 -> RC filter -> TP2 -> PAM8403
    XIAO silk D1 / A1 -> potentiometer wiper
    Potentiometer ends -> 3.3 V and GND

  Operation:
    64 kHz PWM carrier
    250 Hz filtered sine
    100 ms sine burst
    900 ms quiet
    Potentiometer read once before each burst

  Important:
    PWM0 and EasyDMA run continuously.
    The PWM peripheral is never stopped or restarted.

  No Serial code.
*/

#include <Arduino.h>
#include <math.h>
#include <nrf.h>

// -----------------------------------------------------------------------------
// Pin assignments
// -----------------------------------------------------------------------------

// Raw nRF52840 GPIO number:
// XIAO silk D0 is nRF52840 P0.02.
static constexpr uint32_t PWM_GPIO_PIN = 2;

// Arduino analog designation:
// XIAO silk D1 is A1.
static constexpr uint32_t POT_PIN = A1;

// -----------------------------------------------------------------------------
// PWM and waveform configuration
// -----------------------------------------------------------------------------

static constexpr uint16_t PWM_TOP = 250;
static constexpr uint16_t PWM_CENTER = 125;

static constexpr uint16_t SINE_SAMPLES = 64;

/*
  PWM peripheral clock = 16 MHz

  PWM carrier:
    16 MHz / 250 = 64 kHz

  PWM_REFRESH = 3:
    Each sequence entry is held for four PWM periods.

  Waveform frequency:
    64,000 / (64 samples × 4 periods) = 250 Hz
*/
static constexpr uint16_t PWM_REFRESH = 3;

// Preserve the amplitude range already tested successfully.
static constexpr int16_t MIN_AMPLITUDE_COUNTS = 2;
static constexpr int16_t MAX_AMPLITUDE_COUNTS = 20;

static constexpr uint16_t ADC_MAX = 4095;
static constexpr uint8_t POT_AVERAGE_SAMPLES = 8;

// Burst timing.
static constexpr uint32_t BURST_MS = 100;
static constexpr uint32_t QUIET_MS = 900;

// -----------------------------------------------------------------------------
// EasyDMA waveform table
// -----------------------------------------------------------------------------

// EasyDMA data must remain in RAM and be word-aligned.
static uint16_t waveformSequence[SINE_SAMPLES]
    __attribute__((aligned(4)));

// -----------------------------------------------------------------------------
// Potentiometer functions
// -----------------------------------------------------------------------------

static uint16_t readPotentiometer()
{
  uint32_t sum = 0;

  for (uint8_t i = 0; i < POT_AVERAGE_SAMPLES; ++i)
  {
    sum += analogRead(POT_PIN);
  }

  return static_cast<uint16_t>(
      sum / POT_AVERAGE_SAMPLES);
}

static int16_t potToAmplitude(uint16_t potReading)
{
  if (potReading > ADC_MAX)
  {
    potReading = ADC_MAX;
  }

  const uint32_t amplitudeRange =
      MAX_AMPLITUDE_COUNTS -
      MIN_AMPLITUDE_COUNTS;

  const uint32_t scaled =
      static_cast<uint32_t>(potReading) *
      amplitudeRange;

  return static_cast<int16_t>(
      MIN_AMPLITUDE_COUNTS +
      ((scaled + ADC_MAX / 2) / ADC_MAX));
}

// -----------------------------------------------------------------------------
// Waveform-table functions
// -----------------------------------------------------------------------------

static void buildSineSequence(int16_t amplitudeCounts)
{
  for (uint16_t i = 0; i < SINE_SAMPLES; ++i)
  {
    const float phase =
        2.0f * PI *
        static_cast<float>(i) /
        static_cast<float>(SINE_SAMPLES);

    int32_t compareValue =
        static_cast<int32_t>(PWM_CENTER) +
        static_cast<int32_t>(
            lroundf(
                static_cast<float>(amplitudeCounts) *
                sinf(phase)));

    if (compareValue < 0)
    {
      compareValue = 0;
    }
    else if (compareValue > PWM_TOP)
    {
      compareValue = PWM_TOP;
    }

    waveformSequence[i] =
        static_cast<uint16_t>(compareValue);
  }
}

static void buildQuietSequence()
{
  for (uint16_t i = 0; i < SINE_SAMPLES; ++i)
  {
    waveformSequence[i] = PWM_CENTER;
  }
}

// -----------------------------------------------------------------------------
// PWM initialization
// -----------------------------------------------------------------------------

static void configureAndStartPWM()
{
  NRF_PWM0->ENABLE =
      PWM_ENABLE_ENABLE_Disabled;

  // Configure nRF52840 P0.02 as an output.
  NRF_P0->OUTCLR =
      1UL << PWM_GPIO_PIN;

  NRF_P0->PIN_CNF[PWM_GPIO_PIN] =
      (GPIO_PIN_CNF_DIR_Output
       << GPIO_PIN_CNF_DIR_Pos) |

      (GPIO_PIN_CNF_INPUT_Disconnect
       << GPIO_PIN_CNF_INPUT_Pos) |

      (GPIO_PIN_CNF_PULL_Disabled
       << GPIO_PIN_CNF_PULL_Pos) |

      (GPIO_PIN_CNF_DRIVE_S0S1
       << GPIO_PIN_CNF_DRIVE_Pos) |

      (GPIO_PIN_CNF_SENSE_Disabled
       << GPIO_PIN_CNF_SENSE_Pos);

  // Disconnect all PWM outputs first.
  NRF_PWM0->PSEL.OUT[0] = 0xFFFFFFFFUL;
  NRF_PWM0->PSEL.OUT[1] = 0xFFFFFFFFUL;
  NRF_PWM0->PSEL.OUT[2] = 0xFFFFFFFFUL;
  NRF_PWM0->PSEL.OUT[3] = 0xFFFFFFFFUL;

  // PWM0 channel 0 -> P0.02.
  NRF_PWM0->PSEL.OUT[0] =
      (PWM_GPIO_PIN
       << PWM_PSEL_OUT_PIN_Pos) |

      (0UL
       << PWM_PSEL_OUT_PORT_Pos) |

      (PWM_PSEL_OUT_CONNECT_Connected
       << PWM_PSEL_OUT_CONNECT_Pos);

  // Edge-aligned PWM.
  NRF_PWM0->MODE =
      PWM_MODE_UPDOWN_Up
      << PWM_MODE_UPDOWN_Pos;

  // 16 MHz peripheral clock.
  NRF_PWM0->PRESCALER =
      PWM_PRESCALER_PRESCALER_DIV_1
      << PWM_PRESCALER_PRESCALER_Pos;

  // 16 MHz / 250 = 64 kHz.
  NRF_PWM0->COUNTERTOP =
      PWM_TOP
      << PWM_COUNTERTOP_COUNTERTOP_Pos;

  /*
    Common loading:
      One compare value drives PWM channel 0.

    Refresh-count mode:
      Each table entry is held for
      REFRESH + 1 PWM periods.
  */
  NRF_PWM0->DECODER =
      (PWM_DECODER_LOAD_Common
       << PWM_DECODER_LOAD_Pos) |

      (PWM_DECODER_MODE_RefreshCount
       << PWM_DECODER_MODE_Pos);

  // One complete 64-sample waveform.
  NRF_PWM0->SEQ[1].PTR =
      reinterpret_cast<uint32_t>(
          waveformSequence);

  NRF_PWM0->SEQ[1].CNT =
      SINE_SAMPLES
      << PWM_SEQ_CNT_CNT_Pos;

  NRF_PWM0->SEQ[1].REFRESH =
      PWM_REFRESH
      << PWM_SEQ_REFRESH_CNT_Pos;

  NRF_PWM0->SEQ[1].ENDDELAY = 0;

  /*
    Replay sequence 1 continuously.

    Each complete sequence represents one
    4 ms cycle at 250 Hz.
  */
  NRF_PWM0->LOOP =
      1UL << PWM_LOOP_CNT_Pos;

  NRF_PWM0->SHORTS =
      PWM_SHORTS_LOOPSDONE_SEQSTART1_Msk;

  NRF_PWM0->EVENTS_LOOPSDONE = 0;
  NRF_PWM0->EVENTS_SEQSTARTED[1] = 0;

  NRF_PWM0->ENABLE =
      PWM_ENABLE_ENABLE_Enabled;

  NRF_PWM0->TASKS_SEQSTART[1] = 1;
}

// -----------------------------------------------------------------------------
// Arduino entry points
// -----------------------------------------------------------------------------

void setup()
{
  analogReadResolution(12);
  pinMode(POT_PIN, INPUT);

  /*
    Start with all table entries at the
    50% center value.
  */
  buildQuietSequence();

  configureAndStartPWM();

  // Allow the filter output to settle at approximately 1.65 V.
  delay(100);
}

void loop()
{
  /*
    Read the potentiometer only once,
    immediately before the burst.
  */
  const uint16_t potReading =
      readPotentiometer();

  const int16_t amplitudeCounts =
      potToAmplitude(potReading);

  /*
    Replace the quiet table with a sine table.

    Because EasyDMA is running, one transitional
    4 ms waveform cycle may contain a mixture of
    old and new table values.
  */
  buildSineSequence(amplitudeCounts);

  delay(BURST_MS);

  /*
    Replace the sine table with a constant
    50% PWM table.

    The filtered output returns to approximately
    1.65 V, giving zero AC input to the PAM8403.
  */
  buildQuietSequence();

  delay(QUIET_MS);
}
