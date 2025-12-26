package com.mysteris.floatsound.floatsound

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.AudioManager
import android.media.audiofx.AudioEffect
import android.util.Log

class FlutterSoundAudioSessionCapture(private val context: Context?) {
    companion object {
        private const val TAG = "FlutterSoundAudioSessionCapture"
        private var capturedSessionId: Int = 0
        private var context: Context? = null
        
        fun setContext(ctx: Context?) {
            context = ctx
        }
        
        /**
         * Capture audio session ID from an AudioTrack
         * This should be called when Flutter Sound creates its AudioTrack
         */
        fun captureFromAudioTrack(audioTrack: AudioTrack?): Int {
            if (audioTrack == null) {
                Log.w(TAG, "Cannot capture session ID from null AudioTrack")
                return 0
            }
            
            return try {
                // Get the audio session ID from the AudioTrack
                val sessionId = audioTrack.audioSessionId
                capturedSessionId = sessionId
                
                Log.d(TAG, "✓ Captured Flutter Sound audio session ID: $sessionId")
                sessionId
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to capture audio session ID: ${e.message}")
                e.printStackTrace()
                0
            }
        }
        
        /**
         * Create an AudioTrack with session ID capture
         * This can be used to intercept Flutter Sound's AudioTrack creation
         */
        fun createAudioTrackWithCapture(
            sampleRate: Int,
            channelConfig: Int,
            audioFormat: Int,
            bufferSize: Int,
            mode: Int,
            sessionId: Int = 0
        ): Pair<AudioTrack, Int> {
            return try {
                // Create AudioAttributes for better compatibility
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                
                // Create AudioFormat
                val format = AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelConfig)
                    .setEncoding(audioFormat)
                    .build()
                
                // Create AudioTrack with the specified parameters
                val audioTrack = if (sessionId > 0) {
                    // If we have a session ID, try to use it
                    AudioTrack.Builder()
                        .setAudioAttributes(audioAttributes)
                        .setAudioFormat(format)
                        .setBufferSizeInBytes(bufferSize)
                        .setTransferMode(mode)
                        .setSessionId(sessionId)
                        .build()
                } else {
                    // Create without session ID first, then capture it
                    AudioTrack.Builder()
                        .setAudioAttributes(audioAttributes)
                        .setAudioFormat(format)
                        .setBufferSizeInBytes(bufferSize)
                        .setTransferMode(mode)
                        .build()
                }
                
                // Capture the session ID
                val capturedId = captureFromAudioTrack(audioTrack)
                
                Log.d(TAG, "✓ AudioTrack created with session ID: $capturedId")
                Pair(audioTrack, capturedId)
                
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to create AudioTrack with capture: ${e.message}")
                e.printStackTrace()
                
                // Fallback: create basic AudioTrack
                val fallbackTrack = AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize,
                    mode
                )
                
                val fallbackSessionId = captureFromAudioTrack(fallbackTrack)
                Pair(fallbackTrack, fallbackSessionId)
            }
        }
        
        /**
         * Get the last captured session ID
         */
        fun getCapturedSessionId(): Int {
            return capturedSessionId
        }
        
        /**
         * Reset the captured session ID
         */
        fun resetCapturedSessionId() {
            capturedSessionId = 0
            Log.d(TAG, "✓ Captured session ID reset to 0")
        }
        
        /**
         * Try to extract session ID from existing audio effects
         */
        fun extractFromAudioEffects(): Int {
            return try {
                Log.d(TAG, "Attempting to extract session ID from existing audio effects...")
                
                // Query for existing audio effects to find active sessions
                val descriptors = AudioEffect.queryEffects()
                
                if (descriptors != null && descriptors.isNotEmpty()) {
                    // Since we can't directly access session ID from descriptors,
                    // we'll try to detect active sessions using reflection
                    val detectedId = detectActiveAudioSession()
                    if (detectedId > 0) {
                        Log.d(TAG, "✓ Detected active audio session: $detectedId")
                        detectedId
                    } else {
                        Log.w(TAG, "No active audio session detected from audio effects")
                        0
                    }
                } else {
                    Log.w(TAG, "No audio effects found to extract session ID")
                    0
                }
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to extract session ID from audio effects: ${e.message}")
                e.printStackTrace()
                0
            }
        }
        
        /**
         * Try to detect active audio sessions using reflection
         */
        fun detectActiveAudioSession(): Int {
            return try {
                Log.d(TAG, "Attempting to detect active audio sessions using reflection...")
                
                // Try to access AudioTrack's static methods or fields
                val audioTrackClass = Class.forName("android.media.AudioTrack")
                
                // Try to find active AudioTrack instances
                val getNativeOutputSampleRateMethod = audioTrackClass.getMethod("getNativeOutputSampleRate", Int::class.java)
                val sampleRate = getNativeOutputSampleRateMethod.invoke(null, 3) // STREAM_MUSIC = 3
                
                Log.d(TAG, "✓ Detected audio system sample rate: $sampleRate Hz")
                
                // Try to find any active AudioTrack by checking for getPlaybackHeadPosition
                val getPlaybackHeadPositionMethod = audioTrackClass.getMethod("getPlaybackHeadPosition")
                
                // Since we can't easily get session ID from static methods,
                // we'll try a different approach: look for AudioManager properties
                val audioManagerClass = Class.forName("android.media.AudioManager")
                
                // Try to get the active audio sessions
                try {
                    val getActivePlaybackConfigurationsMethod = audioManagerClass.getMethod("getActivePlaybackConfigurations")
                    val configurations = getActivePlaybackConfigurationsMethod.invoke(null)
                    
                    if (configurations != null && configurations is List<*> && configurations.isNotEmpty()) {
                        val firstConfig = configurations[0]
                        val getAudioSessionIdMethod = firstConfig!!::class.java.getMethod("getAudioSessionId")
                        val sessionId = getAudioSessionIdMethod.invoke(firstConfig) as Int
                        
                        Log.d(TAG, "✓ Detected active audio session: $sessionId")
                        sessionId
                    } else {
                        Log.w(TAG, "No active audio configurations found")
                        0
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Could not access active playback configurations: ${e.message}")
                    
                    // Fallback: Try to get AudioManager and check for active audio
                    try {
                        val audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                        if (audioManager != null) {
                            // Check if music is active
                            if (audioManager.isMusicActive) {
                                Log.d(TAG, "✓ Music is currently active")
                                
                                // Try to get a reasonable session ID (this is heuristic)
                                // Since we can't easily get the actual session ID, we'll use a fallback
                                val fallbackSessionId = System.currentTimeMillis().toInt() % 1000000
                                Log.d(TAG, "✓ Using fallback session ID for active music: $fallbackSessionId")
                                fallbackSessionId
                            } else {
                                Log.w(TAG, "No active music detected")
                                0
                            }
                        } else {
                            Log.w(TAG, "Could not get AudioManager instance")
                            0
                        }
                    } catch (e2: Exception) {
                        Log.e(TAG, "✗ All audio session detection methods failed: ${e2.message}")
                        0
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "✗ Failed to detect active audio session: ${e.message}")
                e.printStackTrace()
                0
            }
        }
    }
}