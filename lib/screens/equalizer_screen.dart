import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_player_service.dart';
import '../models/app_state.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  // Equalizer presets
  final List<Map<String, dynamic>> _presets = [
    {'name': '标准', 'icon': Icons.tune},
    {'name': '重低音', 'icon': Icons.speaker},
    {'name': '摇滚', 'icon': Icons.audiotrack},
    {'name': '爵士', 'icon': Icons.piano},
    {'name': '流行', 'icon': Icons.mic},
    {'name': '古典', 'icon': Icons.music_note},
    {'name': '舞曲', 'icon': Icons.nightlife},
    {'name': '嘻哈', 'icon': Icons.music_video},
    {'name': '电子', 'icon': Icons.radio},
    {'name': '原声', 'icon': Icons.surround_sound},
  ];

  String _selectedPreset = '标准';
  bool _isEnabled = true;

  // Frequency bands (Hz)
  final List<double> _frequencies = [60, 230, 910, 3600, 14000];
  final List<double> _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0]; // -10 to +10 dB

  // Preset values
  final Map<String, List<double>> _presetValues = {
    '标准': [0.0, 0.0, 0.0, 0.0, 0.0],
    '重低音': [6.0, 4.0, 2.0, -1.0, -2.0],
    '摇滚': [4.0, 2.0, 3.0, 2.0, 4.0],
    '爵士': [3.0, 2.0, 1.0, 2.0, 3.0],
    '流行': [-1.0, 2.0, 4.0, 2.0, -1.0],
    '古典': [2.0, 1.0, 0.0, 1.0, 2.0],
    '舞曲': [5.0, 3.0, 1.0, 3.0, 5.0],
    '嘻哈': [6.0, 3.0, 1.0, 2.0, 4.0],
    '电子': [4.0, 3.0, 2.0, 3.0, 4.0],
    '原声': [2.0, 3.0, 2.0, 3.0, 2.0],
  };

  void _applyPreset(String preset) {
    final audioPlayerService = AudioPlayerService();

    setState(() {
      _selectedPreset = preset;
      if (_presetValues.containsKey(preset)) {
        for (int i = 0; i < _bandValues.length; i++) {
          _bandValues[i] = _presetValues[preset]![i];
        }
      }
    });

    // Apply to audio player service
    audioPlayerService.setEqualizerPreset(preset, _bandValues);
    _applyEqualizerSettings();
  }

  void _applyEqualizerSettings() {
    final audioPlayerService = AudioPlayerService();

    // Apply settings to audio player
    audioPlayerService.setEqualizerEnabled(_isEnabled);
    audioPlayerService.setEqualizerBands(_bandValues);
  }

  // Show dialog to save custom preset
  void _showSaveCustomPresetDialog() {
    final TextEditingController presetNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '保存自定义预设',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: presetNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '输入预设名称',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final presetName = presetNameController.text.trim();
                if (presetName.isNotEmpty) {
                  final audioPlayerService = AudioPlayerService();
                  await audioPlayerService.saveCustomPreset(
                      presetName, _bandValues);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('预设 "$presetName" 已保存'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                '保存',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoadCustomPresetDialog() async {
    try {
      final audioPlayerService = AudioPlayerService();

      // Get all custom preset names using AudioPlayerService
      final customPresets = await audioPlayerService.getCustomPresetNames();

      if (customPresets.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有找到自定义预设'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              '加载自定义预设',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: customPresets.length,
                itemBuilder: (context, index) {
                  final presetName = customPresets[index];
                  return ListTile(
                    title: Text(
                      presetName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Delete the preset
                        await audioPlayerService.deleteCustomPreset(presetName);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          _showLoadCustomPresetDialog(); // Refresh the dialog
                        }
                      },
                    ),
                    onTap: () async {
                      // Load the preset using AudioPlayerService
                      final bandValues =
                          await audioPlayerService.loadCustomPreset(presetName);
                      if (bandValues != null &&
                          bandValues.length == _bandValues.length) {
                        setState(() {
                          for (int i = 0; i < bandValues.length; i++) {
                            _bandValues[i] = bandValues[i];
                          }
                          _selectedPreset = presetName;
                        });

                        // Apply the loaded preset
                        audioPlayerService.setEqualizerPreset(
                            presetName, _bandValues);
                        audioPlayerService.setEqualizerBands(_bandValues);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('预设 "$presetName" 已加载'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  '取消',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error loading custom presets: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载自定义预设失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          '均衡器',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Row(
            children: [
              Text(
                _isEnabled ? '开启' : '关闭',
                style: TextStyle(
                  color: _isEnabled ? Colors.red : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                  _applyEqualizerSettings();
                },
                activeColor: Colors.red,
                activeTrackColor: Colors.red.withOpacity(0.3),
                inactiveTrackColor: Colors.grey[800],
                inactiveThumbColor: Colors.grey[600],
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Preset selection - more compact and elegant
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = _selectedPreset == preset['name'];

                return GestureDetector(
                  onTap: () {
                    print('Preset button tapped: ${preset["name"]}');
                    _applyPreset(preset['name']);
                    // Apply the preset immediately when tapped
                    final audioPlayerService = AudioPlayerService();
                    audioPlayerService.setEqualizerPreset(
                        preset['name'], _bandValues);
                    audioPlayerService.setEqualizerBands(_bandValues);

                    // Provide visual feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('音效预设 "${preset["name"]}" 已应用'),
                        backgroundColor: Colors.green,
                        duration: const Duration(milliseconds: 1000),
                      ),
                    );
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.red.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.grey[700]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          preset['icon'] as IconData,
                          color: isSelected ? Colors.red : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Frequency bands - more compact and elegant
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Band labels and sliders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_frequencies.length, (index) {
                      return Column(
                        children: [
                          // Slider - more compact
                          SizedBox(
                            height: 160,
                            width: 36,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12),
                                  activeTrackColor: _isEnabled
                                      ? Colors.red
                                      : Colors.grey[600],
                                  inactiveTrackColor: Colors.grey[800],
                                  thumbColor: _isEnabled
                                      ? Colors.red
                                      : Colors.grey[600],
                                  overlayColor: _isEnabled
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: Slider(
                                  value: (_bandValues[index] + 10) /
                                      20, // Convert to 0-1 range
                                  onChanged: _isEnabled
                                      ? (value) {
                                          setState(() {
                                            _bandValues[index] = (value * 20) -
                                                10; // Convert back to -10 to +10
                                            _selectedPreset = 'Custom';
                                          });
                                          _applyEqualizerSettings();
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Frequency label - more subtle
                          Text(
                            '${_frequencies[index].round()}Hz',
                            style: TextStyle(
                              color: _isEnabled
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // dB value - more subtle
                          Text(
                            '${_bandValues[index].toStringAsFixed(1)}dB',
                            style: TextStyle(
                              color: _isEnabled
                                  ? Colors.red.withOpacity(0.8)
                                  : Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Save button
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isEnabled
                        ? () {
                            _showSaveCustomPresetDialog();
                          }
                        : null,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('保存'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _isEnabled ? Colors.white : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _isEnabled
                              ? Colors.grey[700]!
                              : Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Load button
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isEnabled
                        ? () {
                            _showLoadCustomPresetDialog();
                          }
                        : null,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('加载'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _isEnabled ? Colors.white : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _isEnabled
                              ? Colors.grey[700]!
                              : Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Reset button
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isEnabled
                        ? () {
                            _applyPreset('标准');
                          }
                        : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重置'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _isEnabled ? Colors.red : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: _isEnabled
                              ? Colors.red.withOpacity(0.3)
                              : Colors.grey[800]!,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
