# Plan: Moderation-Safe Noise_LFSR15 Generation

## Problem
Roblox rejected Noise_LFSR15.wav due to automated "Disruptive Audio" filters. The raw LFSR noise has:
- Very high spectral density above ~4-6 kHz
- Extremely fast zero crossings (looks like "screeching")
- No tonal structure (pure noise ≈ "harsh noise")
- Near-full-scale RMS (even if peak-safe)

## Solution Strategy

### Phase 1: Generate Filtered Noise Asset
**Goal**: Create Noise_LFSR15_Filtered.wav that passes moderation while maintaining accuracy

**Filtering Pipeline**:
1. **Low-Pass Filter** (CRITICAL - fixes ~80% of rejections)
   - Cutoff: 4.5-5 kHz (DMG speaker barely outputs above ~4 kHz anyway)
   - Slope: 24 dB/octave (or steeper)
   - Type: Butterworth or Chebyshev Type I
   - This removes high-frequency energy that triggers scream detectors

2. **RMS Reduction** (CRITICAL - loudness check)
   - Target Peak: ≤ -6 dBFS
   - Target RMS: -20 to -24 dBFS
   - Method: Normalize to peak first, then apply RMS reduction
   - Roblox checks perceived loudness, not just peak

3. **Temporal Smoothing** (Helpful - prevents impulse detection)
   - Add 0.2-0.5 ms fade-in at start
   - Add 0.2-0.5 ms fade-out at end
   - Prevents "impulse-like" edges that trip scream detectors
   - Must maintain loop-perfect property

4. **Spectral Tilt** (Optional but improves accuracy)
   - Add -3 dB per octave above ~1 kHz
   - Mimics resistor ladder loss and speaker cone inertia
   - Makes it sound more like actual DMG output

5. **Loop-Perfect Verification**
   - First sample must match last sample (within tolerance)
   - If filtering breaks loop, apply circular convolution or adjust

### Phase 2: Accuracy Restoration (If Needed)
**Goal**: Use Roblox audio effects to restore high-frequency content if filtered version sounds too muffled

**Options**:
1. **AudioEqualizer** (Primary method)
   - Boost high frequencies slightly (+1 to +3 dB above 4 kHz)
   - This is safe because we're boosting filtered content, not raw noise
   - Can be adjusted per-game if needed

2. **Accept Filtered Version** (Likely best)
   - The filtered version is actually MORE accurate to real hardware
   - Real DMG never outputs raw digital noise - always goes through:
     - DAC bias
     - Resistor ladder
     - RC low-pass filter
     - Speaker limitations
   - So filtering is actually improving accuracy, not reducing it

### Phase 3: Implementation

**Python Script Changes**:
- Add `scipy.signal` for filtering (or fallback to numpy if unavailable)
- Create `generate_lfsr_noise_filtered()` function
- Apply all filtering steps in correct order
- Verify loop-perfect property
- Generate both versions (original for reference, filtered for upload)

**AudioClient Changes**:
- Update asset ID to use filtered version
- Optionally add high-frequency boost via AudioEqualizer if needed
- Document the filtering approach

## Technical Details

### Filter Specifications
```python
# Low-pass filter
cutoff_freq = 4500  # Hz (4.5 kHz)
nyquist = SAMPLE_RATE / 2
normalized_cutoff = cutoff_freq / nyquist
order = 4  # 24 dB/octave for 4th order Butterworth

# RMS target
target_peak_db = -6  # dBFS
target_rms_db = -22  # dBFS (middle of -20 to -24 range)

# Temporal smoothing
fade_samples = int(SAMPLE_RATE * 0.0003)  # 0.3 ms
```

### Processing Order
1. Generate raw LFSR noise (existing code)
2. Apply low-pass filter
3. Apply spectral tilt (if enabled)
4. Normalize to target peak
5. Apply RMS reduction
6. Apply temporal smoothing (fade in/out)
7. Verify loop-perfect
8. Write WAV file

### Loop-Perfect Verification
```python
# Check if first and last samples match
tolerance = 0.001  # 0.1% tolerance
if abs(samples[0] - samples[-1]) > tolerance:
    # Apply circular smoothing or adjust
    # Blend first/last samples
```

## Files to Modify

1. **generate_gameboy_waveforms.py**
   - Add filtering functions
   - Add filtered noise generation
   - Add verification functions

2. **AudioClient.lua** (if needed)
   - Update asset ID
   - Optionally adjust AudioEqualizer settings

3. **Documentation**
   - Explain why filtering improves accuracy
   - Document filter parameters

## Testing Plan

1. Generate filtered noise
2. Verify loop-perfect property
3. Check spectral characteristics (should show roll-off above 4.5 kHz)
4. Upload to Roblox (should pass moderation)
5. Test in-game (should sound correct)
6. Compare with original (filtered should sound more like real DMG)
7. Adjust AudioEqualizer if needed (unlikely)

## Expected Outcome

- Filtered noise passes Roblox moderation
- Sound is more accurate to real Game Boy hardware
- No need for effects compensation (filtering is the correction)
- Maintains all LFSR properties (pattern, loop-perfect)

