package com.mysteris.floatsound.floatsound

import android.media.audiofx.Equalizer
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class EqualizerMethodChannel(private val flutterEngine: FlutterEngine) {
    private var currentEqualizer: Equalizer? = null
    private var audioSessionId: Int = 0
    
    companion object {
        const val CHANNEL_NAME = "com.mysteris.floatsound/equalizer"
    }
    
    fun setupMethodChannel() {
        Log.d("EqualizerMethodChannel", "=== Setting up Equalizer Method Channel ===")
        Log.d("EqualizerMethodChannel", "Channel name: $CHANNEL_NAME")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            Log.d("EqualizerMethodChannel", "Method called: ${call.method}")
            
            when (call.method) {
                "initializeEqualizer" -> {
                    val sessionId = call.argument<Int>("audioSessionId") ?: 0
                    Log.d("EqualizerMethodChannel", "=== initializeEqualizer called with session ID: $sessionId ===")
                    
                    try {
                        val initResult = initializeEqualizer(sessionId)
                        Log.d("EqualizerMethodChannel", "initializeEqualizer result: $initResult")
                        
                        if (initResult != null) {
                            result.success(initResult)
                        } else {
                            result.error("INIT_FAILED", "Equalizer initialization returned null", null)
                        }
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "✗ Exception during initializeEqualizer: ${e.message}")
                        e.printStackTrace()
                        result.error("INIT_FAILED", "Equalizer initialization failed: ${e.message}", null)
                    }
                }
                
                "setEqualizerEnabled" -> {
            val enabled = call.argument<Boolean>("enabled") ?: false
            Log.d("EqualizerMethodChannel", "=== setEqualizerEnabled called: $enabled ===")
            
            try {
                val success = setEqualizerEnabled(enabled)
                result.success(mapOf("success" to success))
            } catch (e: Exception) {
                Log.e("EqualizerMethodChannel", "✗ Exception during setEqualizerEnabled: ${e.message}")
                result.error("SET_ENABLED_FAILED", "Failed to set equalizer enabled: ${e.message}", null)
            }
        }
                
                "setEqualizerBand" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val level = call.argument<Int>("level") ?: 0
                    Log.d("EqualizerMethodChannel", "=== setEqualizerBand called: band=$band, level=$level ===")
                    
                    try {
                        val success = setEqualizerBand(band, level.toShort())
                        result.success(mapOf("success" to success))
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "✗ Exception during setEqualizerBand: ${e.message}")
                        result.error("SET_BAND_FAILED", "Failed to set equalizer band: ${e.message}", null)
                    }
                }
                
                "getEqualizerBandLevels" -> {
                    println("=== getEqualizerBandLevels called ===")
                    
                    try {
                        val levels = getEqualizerBandLevels()
                        result.success(mapOf("success" to true, "levels" to levels))
                    } catch (e: Exception) {
                        println("✗ Exception during getEqualizerBandLevels: ${e.message}")
                        result.error("GET_LEVELS_FAILED", "Failed to get equalizer band levels: ${e.message}", null)
                    }
                }
                
                "releaseEqualizer" -> {
                    println("=== releaseEqualizer called ===")
                    
                    try {
                        releaseEqualizer()
                        result.success(mapOf("success" to true))
                    } catch (e: Exception) {
                        println("✗ Exception during releaseEqualizer: ${e.message}")
                        result.error("RELEASE_FAILED", "Failed to release equalizer: ${e.message}", null)
                    }
                }
                
                "getEqualizerState" -> {
                    println("=== getEqualizerState called ===")
                    
                    try {
                        val state = getEqualizerState()
                        result.success(state)
                    } catch (e: Exception) {
                        println("✗ Exception during getEqualizerState: ${e.message}")
                        result.error("GET_STATE_FAILED", "Failed to get equalizer state: ${e.message}", null)
                    }
                }
                
                "getEqualizerPreset" -> {
                    Log.d("EqualizerMethodChannel", "=== getEqualizerPreset called ===")
                    
                    try {
                        val preset = getEqualizerPreset()
                        Log.d("EqualizerMethodChannel", "getEqualizerPreset result: $preset")
                        result.success(preset)
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "✗ Exception during getEqualizerPreset: ${e.message}")
                        e.printStackTrace()
                        result.error("GET_PRESET_FAILED", "Failed to get equalizer preset: ${e.message}", null)
                    }
                }
                
                else -> {
                    Log.w("EqualizerMethodChannel", "Unknown method called: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun initializeEqualizer(sessionId: Int): Map<String, Any>? {
        Log.d("EqualizerMethodChannel", "=== Starting Equalizer Initialization ===")
        Log.d("EqualizerMethodChannel", "Session ID: $sessionId")
        Log.d("EqualizerMethodChannel", "Current equalizer instance: $currentEqualizer")
        Log.d("EqualizerMethodChannel", "Current audio session ID: $audioSessionId")
        
        try {
            // Release existing equalizer if any
            releaseEqualizer()
            
            Log.d("EqualizerMethodChannel", "Creating new Equalizer instance...")
            Log.d("EqualizerMethodChannel", "Priority: 0, Session ID: $sessionId")
            
            // Create new equalizer instance
            currentEqualizer = Equalizer(0, sessionId)
            audioSessionId = sessionId
            
            Log.d("EqualizerMethodChannel", "Equalizer created: $currentEqualizer")
            Log.d("EqualizerMethodChannel", "Equalizer enabled: ${currentEqualizer?.enabled}")
            
            currentEqualizer?.let { eq ->
                Log.d("EqualizerMethodChannel", "✓ Equalizer created successfully")
                Log.d("EqualizerMethodChannel", "Equalizer instance: $eq")
                
                // Get equalizer properties
                Log.d("EqualizerMethodChannel", "Getting band level range...")
                val bandLevelRange = listOf(eq.bandLevelRange[0].toInt(), eq.bandLevelRange[1].toInt())
                
                Log.d("EqualizerMethodChannel", "Getting number of bands...")
                val numberOfBands = eq.numberOfBands.toInt()
                
                Log.d("EqualizerMethodChannel", "Getting center frequencies...")
                val centerFrequencies = mutableListOf<Int>()
                
                Log.d("EqualizerMethodChannel", "Number of bands: $numberOfBands")
                Log.d("EqualizerMethodChannel", "Band level range: ${bandLevelRange[0]} to ${bandLevelRange[1]}")
                
                // Get center frequencies for all bands
                for (i in 0 until numberOfBands) {
                    try {
                        val freq = eq.getCenterFreq(i.toShort()).toInt()
                        centerFrequencies.add(freq)
                        Log.d("EqualizerMethodChannel", "Band $i center frequency: $freq")
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "✗ Error getting center frequency for band $i: ${e.message}")
                        centerFrequencies.add(1000) // Default frequency
                    }
                }
                
                // Enable equalizer by default
                Log.d("EqualizerMethodChannel", "Enabling equalizer...")
                eq.enabled = true
                Log.d("EqualizerMethodChannel", "✓ Equalizer enabled: ${eq.enabled}")
                
                val result = mapOf(
                    "success" to true,
                    "numberOfBands" to numberOfBands,
                    "bandLevelRange" to bandLevelRange,
                    "centerFrequencies" to centerFrequencies,
                    "enabled" to eq.enabled
                )
                
                Log.d("EqualizerMethodChannel", "✓ Equalizer initialization completed successfully")
                return result
            }
            
            // Handle null equalizer case
             Log.e("EqualizerMethodChannel", "✗ Failed to create equalizer - null instance")
             return mapOf(
                 "success" to false,
                 "error" to "Failed to create equalizer instance"
             )
            

            
        } catch (e: Exception) {
            Log.e("EqualizerMethodChannel", "✗ Exception during equalizer initialization: ${e.message}")
            Log.e("EqualizerMethodChannel", "Exception type: ${e.javaClass.simpleName}")
            e.printStackTrace()
            
            // Provide more specific error messages based on exception type
            val errorMessage = when (e.javaClass.simpleName) {
                "IllegalArgumentException" -> "Invalid audio session ID: $sessionId"
                "UnsupportedOperationException" -> "Equalizer not supported on this device"
                "RuntimeException" -> "Runtime error: ${e.message}"
                "IllegalStateException" -> "Illegal state: ${e.message}"
                else -> "Exception: ${e.message}"
            }
            
            return mapOf(
                "success" to false,
                "error" to errorMessage,
                "exceptionType" to e.javaClass.simpleName,
                "sessionId" to sessionId
            )
        }
    }
    
    private fun setEqualizerEnabled(enabled: Boolean): Boolean {
        Log.d("EqualizerMethodChannel", "=== setEqualizerEnabled: enabled=$enabled ===")
        
        currentEqualizer?.let { eq ->
            Log.d("EqualizerMethodChannel", "Current equalizer enabled state: ${eq.enabled}")
            eq.enabled = enabled
            Log.d("EqualizerMethodChannel", "Equalizer enabled after setting: ${eq.enabled}")
            return true
        } ?: run {
            Log.e("EqualizerMethodChannel", "✗ Equalizer not initialized")
            return false
        }
    }
    
    private fun setEqualizerBand(band: Int, level: Short): Boolean {
        Log.d("EqualizerMethodChannel", "=== setEqualizerBand: band=$band, level=$level ===")
        
        currentEqualizer?.let { eq ->
            try {
                val currentLevel = eq.getBandLevel(band.toShort())
                Log.d("EqualizerMethodChannel", "Current band $band level: $currentLevel")
                
                eq.setBandLevel(band.toShort(), level)
                val newLevel = eq.getBandLevel(band.toShort())
                Log.d("EqualizerMethodChannel", "Band $band level set to: $newLevel")
                
                return true
            } catch (e: Exception) {
                Log.e("EqualizerMethodChannel", "✗ Failed to set band level: ${e.message}")
                e.printStackTrace()
                return false
            }
        } ?: run {
            Log.e("EqualizerMethodChannel", "✗ Equalizer not initialized")
            return false
        }
    }
    
    private fun getEqualizerBandLevels(): List<Int> {
        Log.d("EqualizerMethodChannel", "Getting equalizer band levels")
        
        currentEqualizer?.let { eq ->
            try {
                val levels = mutableListOf<Int>()
                val numberOfBands = eq.numberOfBands.toInt()
                
                for (i in 0 until numberOfBands) {
                    val level = eq.getBandLevel(i.toShort())
                    levels.add(level.toInt())
                }
                
                Log.d("EqualizerMethodChannel", "✓ Equalizer band levels retrieved: $levels")
                return levels
                
            } catch (e: Exception) {
                Log.e("EqualizerMethodChannel", "✗ Failed to get equalizer band levels: ${e.message}")
                return emptyList()
            }
        } ?: run {
            Log.e("EqualizerMethodChannel", "✗ Cannot get equalizer band levels - equalizer is null")
            return emptyList()
        }
    }
    
    private fun getEqualizerState(): Map<String, Any> {
        Log.d("EqualizerMethodChannel", "Getting equalizer state")
        
        currentEqualizer?.let { eq ->
            try {
                Log.d("EqualizerMethodChannel", "Getting equalizer properties...")
                
                val enabled = eq.enabled
                val numberOfBands = eq.numberOfBands.toInt()
                val bandLevelRange = shortArrayOf(eq.bandLevelRange[0], eq.bandLevelRange[1])
                
                // Get center frequencies
                val centerFrequencies = mutableListOf<Int>()
                for (i in 0 until numberOfBands) {
                    try {
                        val freq = eq.getCenterFreq(i.toShort())
                        centerFrequencies.add(freq)
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "Error getting center frequency for band $i: ${e.message}")
                        centerFrequencies.add(1000) // Default frequency
                    }
                }
                
                // Get current band levels
                val bandLevels = mutableListOf<Int>()
                for (i in 0 until numberOfBands) {
                    try {
                        val level = eq.getBandLevel(i.toShort())
                        bandLevels.add(level.toInt())
                    } catch (e: Exception) {
                        Log.e("EqualizerMethodChannel", "Error getting band level for band $i: ${e.message}")
                        bandLevels.add(0) // Default level
                    }
                }
                
                val state = mapOf(
                    "initialized" to true,
                    "enabled" to enabled,
                    "numberOfBands" to numberOfBands,
                    "bandLevelRange" to bandLevelRange.toList(),
                    "centerFrequencies" to centerFrequencies,
                    "bandLevels" to bandLevels,
                    "audioSessionId" to audioSessionId,
                    "success" to true
                )
                
                Log.d("EqualizerMethodChannel", "✓ Equalizer state retrieved successfully: $state")
                return state
                
            } catch (e: Exception) {
                Log.e("EqualizerMethodChannel", "✗ Error getting equalizer state: ${e.message}")
                e.printStackTrace()
                
                return mapOf(
                    "initialized" to true,
                    "enabled" to false,
                    "numberOfBands" to 0,
                    "bandLevelRange" to listOf(-1500, 1500),
                    "centerFrequencies" to emptyList<Int>(),
                    "bandLevels" to emptyList<Int>(),
                    "audioSessionId" to audioSessionId,
                    "success" to false,
                    "error" to "Error getting state: ${e.message}"
                )
            }
        } ?: run {
            Log.e("EqualizerMethodChannel", "✗ Equalizer not initialized - cannot get state")
            return mapOf(
                "initialized" to false,
                "enabled" to false,
                "numberOfBands" to 0,
                "bandLevelRange" to listOf(-1500, 1500),
                "centerFrequencies" to emptyList<Int>(),
                "bandLevels" to emptyList<Int>(),
                "audioSessionId" to 0,
                "success" to false,
                "error" to "Equalizer not initialized"
            )
        }
    }
    
    private fun getEqualizerPreset(): Int {
        Log.d("EqualizerMethodChannel", "=== getEqualizerPreset ===")
        
        currentEqualizer?.let { eq ->
            try {
                val preset = eq.currentPreset.toInt()
                Log.d("EqualizerMethodChannel", "Current preset: $preset")
                return preset
            } catch (e: Exception) {
                Log.e("EqualizerMethodChannel", "✗ Failed to get current preset: ${e.message}")
                return -1
            }
        } ?: run {
            Log.e("EqualizerMethodChannel", "✗ Equalizer not initialized")
            return -1
        }
    }
    
    private fun releaseEqualizer() {
        Log.d("EqualizerMethodChannel", "=== releaseEqualizer ===")
        
        currentEqualizer?.let { eq ->
            Log.d("EqualizerMethodChannel", "Releasing equalizer: $eq")
            eq.release()
            currentEqualizer = null
            Log.d("EqualizerMethodChannel", "✓ Equalizer released successfully")
        } ?: run {
            Log.d("EqualizerMethodChannel", "No equalizer to release")
        }
    }
}