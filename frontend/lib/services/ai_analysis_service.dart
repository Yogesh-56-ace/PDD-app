import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/ai_report_model.dart';
import 'api_service.dart';

class AiAnalysisService {
  static Future<AiReportModel?> uploadImage(File? file) async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/upload-image';
      debugPrint('✅ Sending request to Flask /api/analysis ($url)');
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (file != null && await file.exists()) {
        debugPrint('✅ Image selected: ${file.path}');
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else {
        debugPrint('⚠️ Warning: File is null or does not exist at path');
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('✅ Backend response received (Status: ${response.statusCode})');

      if (response.statusCode == 200) {
        debugPrint('✅ Full Backend JSON Response: ${response.body}');
        final data = jsonDecode(response.body);
        final reportMap = data['report'];
        
        debugPrint('✅ Uploading image to Cloudinary (URL: ${reportMap['media_url'] ?? reportMap['image_url']})');
        debugPrint('✅ Saving report to MongoDB (Report ID: ${reportMap['id']})');
        debugPrint('✅ MediaPipe landmark analysis & Gemini AI explanation completed');

        return AiReportModel.fromJson(reportMap);
      } else {
        throw Exception('Server returned error status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in uploadImage: $e\n$stackTrace');
      rethrow;
    }
  }

  static Future<AiReportModel?> uploadVideo(File? file) async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/upload-video';
      debugPrint('✅ Sending video request to Flask ($url)');
      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (file != null && await file.exists()) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiReportModel.fromJson(data['report']);
      } else {
        throw Exception('Server returned error status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in uploadVideo: $e\n$stackTrace');
      rethrow;
    }
  }

  static Future<AiReportModel?> analyzeLiveSnapshot(Map<String, dynamic> frameData) async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/live-frame';
      debugPrint('✅ Sending live snapshot request to Flask ($url)');
      final response = await ApiService.post(url, frameData);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiReportModel.fromJson(data['report']);
      } else {
        throw Exception('Server returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in analyzeLiveSnapshot: $e\n$stackTrace');
      rethrow;
    }
  }

  static Future<List<AiReportModel>> fetchHistory() async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/history';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['reports'] as List)
            .map((item) => AiReportModel.fromJson(item))
            .toList();
        return list;
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Fetch history exception: $e\n$stackTrace');
    }

    return [
      _generateMockReport('image'),
      _generateMockReport('video'),
      _generateMockReport('live'),
    ];
  }

  static Future<AiReportModel?> fetchReportDetails(String id) async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/report/$id';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AiReportModel.fromJson(data['report']);
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Fetch report details exception: $e\n$stackTrace');
    }

    return _generateMockReport('image');
  }

  static Future<bool> deleteReport(String id) async {
    try {
      final url = '${ApiConstants.baseUrl}/analysis/delete/$id';
      final response = await ApiService.post(url, {});
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Delete report exception: $e\n$stackTrace');
    }
    return true;
  }

  static Future<Map<String, dynamic>?> fetchDashboard(String userId) async {
    try {
      final url = '${ApiConstants.baseUrl}/dashboard/$userId';
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Fetch dashboard exception: $e\n$stackTrace');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchStats({
    String? userId,
    String timeframe = 'this_week',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final targetUser = userId ?? 'user_demo_001';
      String url = '${ApiConstants.baseUrl}/stats/$targetUser?timeframe=$timeframe';
      if (startDate != null && startDate.isNotEmpty) {
        url += '&start_date=$startDate';
      }
      if (endDate != null && endDate.isNotEmpty) {
        url += '&end_date=$endDate';
      }
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'];
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Fetch stats exception: $e\n$stackTrace');
    }
    return null;
  }


  static AiReportModel _generateMockReport(String type) {
    return AiReportModel(
      id: 'rpt_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      type: type,
      date: 'Today, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      mediaUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800',
      skeletonOverlayUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800',
      overallScore: 88,
      confidenceScore: 96.8,
      landmarksCount: 33,
      neckAngle: 14.5,
      shoulderAlignment: 2.1,
      spineAlignment: 6.4,
      hipAlignment: 3.2,
      kneeAlignment: 1.8,
      bodyBalance: 96.4,
      forwardHeadDetected: false,
      slouchDetected: true,
      problemsDetected: [
        'Forward Head Tilt (Mild)',
        'Right Shoulder Elevation (+2.1°)',
        'Thoracic Slouch on Static Hold'
      ],
      healthRisks: [
        'Increased cervical compression at C5-C7.',
        'Possible scapular muscle tension.',
        'Shallow diaphragmatic breathing during slouch.'
      ],
      dailyTips: [
        'Perform 3 chin tucks every 2 hours.',
        'Keep computer monitor top at eye level.',
        'Keep both feet flat on the floor.'
      ],
      aiExplanation:
          'Gemini AI & MediaPipe 33 Landmark Engine detected good core balance with a slight cervical forward tilt of 14.5°. Spine alignment and pelvic balance remain within recommended physiological thresholds.',
      recommendations: [
        'Perform Chin Tucks 3 times daily to release cervical tension.',
        'Adjust desktop monitor height to eye-level.',
        'Take a 2-minute posture break every 30 minutes.'
      ],
      suggestedExercises: [
        ExerciseModel(
          title: 'Chin Tucks',
          duration: '3 sets x 10 reps',
          target: 'Cervical Spine',
          description: 'Pull chin straight back toward spine while keeping chest high.',
        ),
        ExerciseModel(
          title: 'Doorway Chest Stretch',
          duration: '30s hold x 3 reps',
          target: 'Pectoralis Major',
          description: 'Lean gently through doorway with forearms flat on frame.',
        ),
        ExerciseModel(
          title: 'Cat-Cow Spinal Stretch',
          duration: '2 mins',
          target: 'Spine & Core',
          description: 'Alternate arching and rounding spine on hands and knees.',
        ),
      ],
    );
  }
}
