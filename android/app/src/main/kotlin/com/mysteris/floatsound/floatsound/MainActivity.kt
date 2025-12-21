package com.mysteris.floatsound.floatsound

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.media.AudioManager

class MainActivity: FlutterActivity() {
    private lateinit var equalizerMethodChannel: EqualizerMethodChannel
    private lateinit var volumeChannel: MethodChannel
    private var currentAudioSessionId: Int = 0
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize equalizer method channel
        equalizerMethodChannel = EqualizerMethodChannel(flutterEngine)
        equalizerMethodChannel.setupMethodChannel()
        
        // Setup volume control method channel
        setupVolumeChannel()
        
        // Setup additional method channels
        setupAudioChannel()
        setupKeyChannel()
    }
    
    private fun setupVolumeChannel() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            volumeChannel = MethodChannel(messenger, "com.mysteris.floatsound/volume")
            volumeChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showVolumeBar" -> {
                        showVolumeBar()
                        result.success(true)
                    }
                    "showVolumeControl" -> {
                        showSystemVolumeControl()
                        result.success(true)
                    }
                    "adjustVolume" -> {
                        val showUI = call.argument<Boolean>("showUI") ?: false
                        adjustVolume(showUI)
                        result.success(true)
                    }
                    "simulateVolumeKey" -> {
                        simulateVolumeKey()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
    
    private fun setupAudioChannel() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val audioChannel = MethodChannel(messenger, "com.mysteris.floatsound/audio")
            audioChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "adjustVolume" -> {
                        val showUI = call.argument<Boolean>("showUI") ?: false
                        adjustVolume(showUI)
                        result.success(true)
                    }
                    "getAudioSessionId" -> {
                        val sessionId = getAudioSessionId()
                        result.success(sessionId)
                    }
                    "setAudioSessionId" -> {
                        val sessionId = call.argument<Int>("sessionId") ?: 0
                        setAudioSessionId(sessionId)
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
    
    private fun setupKeyChannel() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val keyChannel = MethodChannel(messenger, "com.mysteris.floatsound/key")
            keyChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "simulateVolumeKey" -> {
                        simulateVolumeKey()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
    
    private fun showVolumeBar() {
        try {
            // Method to show only the volume bar (not the full settings)
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            
            // Show volume bar by adjusting volume slightly with UI flag
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            
            if (currentVolume < maxVolume) {
                // Increase volume by 1 to show the bar
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_RAISE,
                    AudioManager.FLAG_SHOW_UI
                )
                // Immediately return to original volume
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_LOWER,
                    0 // No UI flag for the second adjustment
                )
            } else {
                // If already at max, decrease then increase
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_LOWER,
                    AudioManager.FLAG_SHOW_UI
                )
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_RAISE,
                    0
                )
            }
            
            println("Volume bar shown successfully")
            
        } catch (e: Exception) {
            println("Error showing volume bar: ${e.message}")
            e.printStackTrace()
            
            // Fallback to system volume control
            showSystemVolumeControl()
        }
    }
    
    private fun adjustVolume(showUI: Boolean) {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            val flags = if (showUI) AudioManager.FLAG_SHOW_UI else 0
            
            // Just trigger a volume adjustment to show the UI
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_SAME,
                flags
            )
            
            println("Volume adjustment triggered with UI: $showUI")
            
        } catch (e: Exception) {
            println("Error adjusting volume: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun simulateVolumeKey() {
        try {
            // Simulate volume key press to trigger system volume bar
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            
            // Try to trigger volume bar by simulating key event
            val instrumentation = android.app.Instrumentation()
            
            try {
                // Simulate volume up key
                instrumentation.sendKeyDownUpSync(android.view.KeyEvent.KEYCODE_VOLUME_UP)
                println("Volume key simulation successful")
            } catch (e: Exception) {
                println("Instrumentation method failed: ${e.message}")
                
                // Fallback: use audio manager
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_RAISE,
                    AudioManager.FLAG_SHOW_UI
                )
            }
            
        } catch (e: Exception) {
            println("Error simulating volume key: ${e.message}")
            e.printStackTrace()
            
            // Final fallback
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_SAME,
                AudioManager.FLAG_SHOW_UI
            )
        }
    }

    private fun showSystemVolumeControl() {
        try {
            // Method 1: Try to show system volume panel
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                AudioManager.ADJUST_SAME,
                AudioManager.FLAG_SHOW_UI
            )
            
            // Method 2: Alternative approach using system settings (fallback)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                try {
                    val intent = Intent(Settings.ACTION_SOUND_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                } catch (e: Exception) {
                    // Fallback to audio manager method
                    val volumeIntent = Intent("android.settings.SOUND_SETTINGS")
                    volumeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(volumeIntent)
                }
            }
        } catch (e: Exception) {
            // Final fallback - just try to trigger any volume-related activity
            try {
                val fallbackIntent = Intent("android.intent.action.MAIN")
                fallbackIntent.setClassName("com.android.settings", "com.android.settings.SoundSettings")
                fallbackIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(fallbackIntent)
            } catch (e2: Exception) {
                // If all else fails, the method channel will still return success
                // but the volume control might not show
                e2.printStackTrace()
            }
        }
    }

    // Get audio session ID for equalizer
    private fun getAudioSessionId(): Int {
        return try {
            // Return the stored audio session ID
            // This should be set when playback starts via setAudioSessionId
            println("Getting audio session ID: $currentAudioSessionId")
            
            // If no session ID is stored, try to get it from audio manager
            if (currentAudioSessionId == 0) {
                val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
                
                // Try to get the active audio session ID
                // For Android O and above, we can try to get the active playback sessions
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    try {
                        // Get active audio sessions - this is a system service approach
                        // Note: This might not work for all Android versions
                        val sessions = audioManager.activePlaybackConfigurations
                        if (sessions != null && sessions.isNotEmpty()) {
                            val session = sessions[0]
                            println("Found active audio playback configuration: $session")
                            // Note: AudioPlaybackConfiguration doesn't directly expose session ID
                            // We'll use a default session ID or try to infer it from the configuration
                            currentAudioSessionId = 0 // Use global session as fallback
                            println("Using global audio session ID as fallback: $currentAudioSessionId")
                        }
                    } catch (e: Exception) {
                        println("Error getting active audio sessions: ${e.message}")
                    }
                }
                
                // If still no session ID, use global equalizer (session ID 0)
                if (currentAudioSessionId == 0) {
                    currentAudioSessionId = 0 // Global audio session
                    println("Using global audio session ID: $currentAudioSessionId")
                }
            }
            
            currentAudioSessionId
        } catch (e: Exception) {
            println("Error getting audio session ID: ${e.message}")
            0 // Return default session ID
        }
    }

    // Set audio session ID (called when Flutter Sound player starts)
    fun setAudioSessionId(sessionId: Int) {
        currentAudioSessionId = sessionId
        println("Audio session ID set to: $sessionId")
    }
}
