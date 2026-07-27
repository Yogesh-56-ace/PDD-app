import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import 'processing_screen.dart';

import '../widgets/custom_app_bar.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (pickedFile != null) {
        setState(() {
          _selectedVideo = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select video: $e')),
      );
    }
  }

  void _startAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          mode: 'video',
          mediaFile: _selectedVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBody,
      appBar: const CustomAppBar(title: 'Upload Video'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Multi-Frame Video AI Analysis', style: AppTextStyles.h2),
              const SizedBox(height: 6),
              Text(
                'Upload a short 10-60 second posture video to analyze dynamic spinal movement and gait telemetry.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 24),

              // Video preview zone
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedVideo != null ? AppColors.primary : AppColors.borderLight,
                    width: _selectedVideo != null ? 2 : 1,
                  ),
                  boxShadow: const [AppColors.shadowCard],
                ),
                child: _selectedVideo != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.film, color: AppColors.primary, size: 48),
                          ),
                          const SizedBox(height: 16),
                          Text('Video Selected', style: AppTextStyles.h3),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _selectedVideo!.path.split('/').last,
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => setState(() => _selectedVideo = null),
                            child: Text(
                              'Change Video',
                              style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.video, color: AppColors.primary, size: 36),
                          ),
                          const SizedBox(height: 16),
                          Text('Select Posture Video', style: AppTextStyles.h3),
                          const SizedBox(height: 6),
                          Text('MP4, MOV or AVI up to 50MB', style: AppTextStyles.caption),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              CustomButton(
                text: 'Select Video File',
                icon: LucideIcons.fileVideo,
                isSecondary: true,
                onPressed: _pickVideo,
              ),

              const SizedBox(height: 16),

              CustomButton(
                text: 'Analyze Video Posture',
                icon: LucideIcons.sparkles,
                onPressed: _selectedVideo == null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a video file first.')),
                        );
                      }
                    : _startAnalysis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
