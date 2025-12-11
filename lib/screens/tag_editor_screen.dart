import 'dart:io';
import 'package:flutter/material.dart';
import '../services/tag_editor_service.dart';
import '../models/music.dart';

class TagEditorScreen extends StatefulWidget {
  final Music music;
  
  const TagEditorScreen({super.key, required this.music});
  
  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
  final TagEditorService _tagEditorService = TagEditorService();
  
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _artist = '';
  String _album = '';
  String _genre = '';
  int _year = 0;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadTags();
  }
  
  // Load existing tags
  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tags = await _tagEditorService.readTags(widget.music.filePath);
      setState(() {
        _title = tags['title'] ?? widget.music.title;
        _artist = tags['artist'] ?? widget.music.artist;
        _album = tags['album'] ?? widget.music.album;
        _genre = tags['genre'] ?? widget.music.genre;
        _year = tags['year'] ?? widget.music.year;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tags: $e')),
      );
    }
  }
  
  // Save tags
  Future<void> _saveTags() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _tagEditorService.writeTags(widget.music.filePath, {
          'title': _title,
          'artist': _artist,
          'album': _album,
          'genre': _genre,
          'year': _year,
        });
        
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tags saved successfully')),
        );
        
        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tags: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Tags'),
        actions: [
          TextButton(
            onPressed: _saveTags,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Album art
                    if (widget.music.coverPath != null)
                      Image.file(
                        File(widget.music.coverPath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                      ),
                    const SizedBox(height: 20),
                    
                    // Title
                    TextFormField(
                      initialValue: _title,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _title = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Artist
                    TextFormField(
                      initialValue: _artist,
                      decoration: InputDecoration(
                        labelText: 'Artist',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) {
                        _artist = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Album
                    TextFormField(
                      initialValue: _album,
                      decoration: InputDecoration(
                        labelText: 'Album',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) {
                        _album = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Genre
                    TextFormField(
                      initialValue: _genre,
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onSaved: (value) {
                        _genre = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Year
                    TextFormField(
                      initialValue: _year.toString(),
                      decoration: InputDecoration(
                        labelText: 'Year',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final year = int.tryParse(value);
                        if (year == null) {
                          return 'Please enter a valid year';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _year = value != null && value.isNotEmpty ? int.parse(value) : 0;
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
