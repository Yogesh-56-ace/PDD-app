import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/ai_report_model.dart';
import '../widgets/base_layout.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/posture_gauge.dart';
import '../widgets/status_badge.dart';

class AiReportScreen extends StatefulWidget {
  final AiReportModel? report;
  final bool embedInScaffold;

  const AiReportScreen({super.key, this.report, this.embedInScaffold = true});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  late bool neckError;
  late bool leftShoulderError;
  late bool rightShoulderError;
  late bool spineError;
  late bool pelvisError;
  late bool kneeError;
  late bool isExcellent;
  late String pose; // 'sitting' or 'standing'

  String? _selectedPart;
  String? _selectedProblemName;
  String? _selectedCorrectionTip;
  bool _selectedIsError = false;

  @override
  void initState() {
    super.initState();
    try {
      _initData();
    } catch (e, stackTrace) {
      debugPrint('❌ Critical Exception inside initState: $e\n$stackTrace');
      _setDefaults();
    }
  }

  void _initData() {
    try {
      final r = widget.report;
      debugPrint('✅ AiReportScreen received report data: $r');
      if (r != null) {
        dynamic dr = r;
        debugPrint('✅ Report Details: ID=${dr.id}, Score=${dr.overallScore}');
        
        // Defensively handle potential nulls at runtime
        neckError = (dr.forwardHeadDetected == true) || (dr.neckAngle ?? 0.0) > 18.0;
        leftShoulderError = (dr.shoulderAlignment ?? 0.0) > 3.0;
        rightShoulderError = (dr.shoulderAlignment ?? 0.0) > 3.0;
        spineError = (dr.slouchDetected == true) || (dr.spineAlignment ?? 0.0) > 8.0;
        pelvisError = (dr.hipAlignment ?? 0.0) > 3.5;
        kneeError = (dr.kneeAlignment ?? 0.0) > 3.0;
        isExcellent = !neckError && !leftShoulderError && !rightShoulderError && !spineError && !pelvisError && !kneeError;

        // Dynamic Pose Detection
        final problemsList = dr.problemsDetected as List<dynamic>? ?? [];
        final hasSlouchProblem = problemsList.any((p) => p.toString().toLowerCase().contains('slouch') || p.toString().toLowerCase().contains('kyphosis'));
        if (dr.slouchDetected == true || hasSlouchProblem) {
          pose = 'sitting';
        } else {
          pose = 'standing';
        }
      } else {
        _setDefaults();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error inside _initData: $e\n$stackTrace');
      _setDefaults();
    }

    if (isExcellent) {
      _selectPart('Body Alignment');
    } else if (neckError) {
      _selectPart('Neck');
    } else if (leftShoulderError) {
      _selectPart('Left Shoulder');
    } else if (spineError) {
      _selectPart('Upper Back');
    } else if (pelvisError) {
      _selectPart('Pelvis');
    } else {
      _selectPart('Body Alignment');
    }
  }

  void _setDefaults() {
    neckError = true;
    leftShoulderError = true;
    rightShoulderError = false;
    spineError = true;
    pelvisError = false;
    kneeError = false;
    isExcellent = false;
    pose = 'standing';
  }

  void _selectPart(String part) {
    setState(() {
      _selectedPart = part;
      if (part == 'Neck') {
        _selectedProblemName = 'Forward Head Posture';
        _selectedCorrectionTip = 'Perform chin tucks. Keep head aligned over shoulders.';
        _selectedIsError = neckError;
      } else if (part == 'Left Shoulder') {
        _selectedProblemName = 'Shoulder Tilt';
        _selectedCorrectionTip = 'Perform shoulder stretches. Avoid carrying heavy bags on one side.';
        _selectedIsError = leftShoulderError;
      } else if (part == 'Right Shoulder') {
        _selectedProblemName = 'Shoulder Tilt';
        _selectedCorrectionTip = 'Perform shoulder stretches. Avoid carrying heavy bags on one side.';
        _selectedIsError = rightShoulderError;
      } else if (part == 'Upper Back') {
        _selectedProblemName = 'Rounded Back';
        _selectedCorrectionTip = 'Sit upright and strengthen upper back muscles.';
        _selectedIsError = spineError;
      } else if (part == 'Pelvis') {
        _selectedProblemName = 'Pelvic Tilt';
        _selectedCorrectionTip = 'Perform core strengthening exercises and pelvic tilts.';
        _selectedIsError = pelvisError;
      } else if (part == 'Left Knee') {
        _selectedProblemName = 'Knee Joint Deviation';
        _selectedCorrectionTip = 'Perform squats and practice weight-balanced standing.';
        _selectedIsError = kneeError;
      } else if (part == 'Right Knee') {
        _selectedProblemName = 'Knee Joint Deviation';
        _selectedCorrectionTip = 'Perform squats and practice weight-balanced standing.';
        _selectedIsError = kneeError;
      } else {
        _selectedPart = 'Body Alignment';
        _selectedProblemName = 'Excellent Posture';
        _selectedCorrectionTip = 'All body parts are currently aligned correctly.';
        _selectedIsError = false;
      }
    });
  }

  Widget _buildProblemSummaryItem(String label, String problem, String solution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppColors.shadowSoft],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.split(' ')[0], // emoji
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label.substring(label.indexOf(' ') + 1), // text name
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
              children: [
                const TextSpan(text: 'Problem: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: problem),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              children: [
                const TextSpan(text: 'Solution: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                TextSpan(text: solution),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final r = widget.report;
      final int score = r?.overallScore ?? 88;

      final reportBody = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // 1. Overall Posture Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall Posture Score', style: AppTextStyles.h2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isExcellent ? AppColors.primaryLight : AppColors.alertLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isExcellent ? AppColors.primary : AppColors.alert),
                      ),
                      child: Text(
                        '$score% Score',
                        style: TextStyle(
                          color: isExcellent ? AppColors.primary : AppColors.alert,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isExcellent ? 'Excellent Posture' : 'Issues Detected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isExcellent ? AppColors.primary : AppColors.alert,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User Pose Mode: ${pose[0].toUpperCase()}${pose.substring(1)} Assessment',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // 2. Interactive Body Diagram
                Center(
                  child: Container(
                    width: 150,
                    height: 250,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [AppColors.shadowCard],
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        const double w = 130;
                        const double h = 230;
                        final x = details.localPosition.dx * 150 / w;
                        final y = details.localPosition.dy * 250 / h;
                        
                        final double shoulderTapY = pose == 'sitting' ? 70 : 60;
                        final double pelvisTapY = 130;
                        
                        if (y < shoulderTapY - 15) {
                          if (neckError) _selectPart('Neck');
                        } else if (y >= shoulderTapY - 15 && y < shoulderTapY + 15) {
                          if (x < 75) {
                            if (leftShoulderError) _selectPart('Left Shoulder');
                          } else {
                            if (rightShoulderError) _selectPart('Right Shoulder');
                          }
                        } else if (y >= shoulderTapY + 15 && y < pelvisTapY - 10) {
                          if (spineError) _selectPart('Upper Back');
                        } else if (y >= pelvisTapY - 10 && y < pelvisTapY + 15) {
                          if (pelvisError) _selectPart('Pelvis');
                        } else if (y >= pelvisTapY + 15) {
                          if (x < 75) {
                            if (kneeError) _selectPart('Left Knee');
                          } else {
                            if (kneeError) _selectPart('Right Knee');
                          }
                        }
                      },
                      child: CustomPaint(
                        size: const Size(130, 230),
                        painter: BodyMapPainter(
                          isExcellent: isExcellent,
                          neckError: neckError,
                          leftShoulderError: leftShoulderError,
                          rightShoulderError: rightShoulderError,
                          spineError: spineError,
                          pelvisError: pelvisError,
                          kneeError: kneeError,
                          selectedPart: _selectedPart,
                          pose: pose,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Interactive Detail Info Box
                if (_selectedPart != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedIsError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedIsError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedIsError ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                              color: _selectedIsError ? Colors.red : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedPart!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedIsError ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Problem: $_selectedProblemName',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solution: $_selectedCorrectionTip',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),

                // 4. Problems Detected Summary List
                Text('Problems Detected', style: AppTextStyles.h2),
                const SizedBox(height: 12),
                if (isExcellent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Excellent Posture! No issues found.',
                          style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      if (neckError)
                        _buildProblemSummaryItem('🔴 Neck', 'Forward Head Posture', 'Chin tuck exercise, Keep head aligned over shoulders'),
                      if (leftShoulderError)
                        _buildProblemSummaryItem('🟠 Left Shoulder', 'Shoulder Tilt', 'Shoulder stretch, Avoid carrying heavy bags on one side'),
                      if (rightShoulderError)
                        _buildProblemSummaryItem('🟠 Right Shoulder', 'Shoulder Tilt', 'Shoulder stretch, Avoid carrying heavy bags on one side'),
                      if (spineError)
                        _buildProblemSummaryItem('🔴 Upper Back', 'Rounded Back', 'Sit upright, Strengthen upper back muscles'),
                      if (pelvisError)
                        _buildProblemSummaryItem('🔴 Pelvis', 'Pelvic Tilt', 'Core strengthening exercises, pelvic tilts'),
                      if (kneeError)
                        _buildProblemSummaryItem('🔴 Knee', 'Knee Joint Deviation', 'Squats, weight-balanced standing'),
                    ],
                  ),

                const SizedBox(height: 24),

                // 5. Recommended Exercises Section
                Text('Recommended Exercises', style: AppTextStyles.h2),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendedExercises.length,
                  itemBuilder: (context, index) {
                    final ex = recommendedExercises[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [AppColors.shadowSoft],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(ex.title, style: AppTextStyles.h3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ex.duration,
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Target: ${ex.target}', style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          Text(ex.description, style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                
                // Return to main dashboard button
                CustomButton(
                  text: 'Back to Dashboard',
                  icon: LucideIcons.home,
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                ),
                const SizedBox(height: 24),
              ],
            ),
      );

      if (!widget.embedInScaffold) {
        return reportBody;
      }

      return BaseLayout(
        title: 'AI Posture Report',
        body: reportBody,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Exception inside AiReportScreen build: $e\n$stackTrace');
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Error', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Failed to render AI Posture Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(
                  'The screen failed to render due to the following error:\n\n$e',
                  style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class ExerciseCardModel {
  final String title;
  final String duration;
  final String target;
  final String description;

  ExerciseCardModel({
    required this.title,
    required this.duration,
    required this.target,
    required this.description,
  });
}

final List<ExerciseCardModel> recommendedExercises = [
  ExerciseCardModel(
    title: 'Chin Tuck',
    duration: '3 sets x 10 reps',
    target: 'Cervical Spine',
    description: 'Pull chin straight back toward spine while maintaining upright chest.',
  ),
  ExerciseCardModel(
    title: 'Shoulder Stretch',
    duration: '30s hold x 3 reps',
    target: 'Shoulders & Chest',
    description: 'Lean gently through doorway with forearms flat on frame.',
  ),
  ExerciseCardModel(
    title: 'Wall Angel',
    duration: '3 sets x 12 reps',
    target: 'Upper Back & Shoulders',
    description: 'Slide back and arms up/down against a wall while keeping contact.',
  ),
  ExerciseCardModel(
    title: 'Cat-Cow Stretch',
    duration: '2 mins dynamic',
    target: 'Spinal Curvature',
    description: 'Alternate arching and rounding spine on hands and knees.',
  ),
  ExerciseCardModel(
    title: 'Back Extension',
    duration: '10 reps hold 5s',
    target: 'Lower Back & Core',
    description: 'Lie flat on stomach and lift chest gently while keeping hips on floor.',
  ),
];

class BodyMapPainter extends CustomPainter {
  final bool isExcellent;
  final bool neckError;
  final bool leftShoulderError;
  final bool rightShoulderError;
  final bool spineError;
  final bool pelvisError;
  final bool kneeError;
  final String? selectedPart;
  final String pose;

  BodyMapPainter({
    required this.isExcellent,
    required this.neckError,
    required this.leftShoulderError,
    required this.rightShoulderError,
    required this.spineError,
    required this.pelvisError,
    required this.kneeError,
    this.selectedPart,
    required this.pose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final double w = size.width;
      final double h = size.height;

      // Scale coordinates from 150x250 viewport to canvas size
      double sx(double x) => x * w / 150;
      double sy(double y) => y * h / 250;

      final Color normalColor = Colors.blueGrey.shade100;
      final Color excellentColor = const Color(0xFF10B981);
      final Color errorColor = const Color(0xFFEF4444);
      final Color warningColor = const Color(0xFFF59E0B);

      Color getPartColor(bool hasError, {bool isWarning = false}) {
        if (isExcellent) return excellentColor;
        if (hasError) return isWarning ? warningColor : errorColor;
        return normalColor;
      }

      // Paint definition
      final Paint linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0;

      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill;

      final Paint dashedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.5;

      void drawDashedLine(Offset p1, Offset p2, Color color) {
        dashedPaint.color = color;
        const double dashWidth = 4.0;
        const double dashSpace = 4.0;
        final double distance = (p2 - p1).distance;
        if (distance == 0) return;
        final Offset direction = (p2 - p1) / distance;
        double currentDist = 0.0;
        while (currentDist < distance) {
          final Offset start = p1 + direction * currentDist;
          final double endDist = math.min(currentDist + dashWidth, distance);
          final Offset end = p1 + direction * endDist;
          canvas.drawLine(start, end, dashedPaint);
          currentDist += dashWidth + dashSpace;
        }
      }

      // Coordinates setup based on pose mode
      final double headY = pose == 'sitting' ? sy(40) : sy(30);
      final double neckEndY = pose == 'sitting' ? sy(68) : sy(58);
      
      final double shoulderY = pose == 'sitting' ? sy(70) : sy(60);
      final double leftShoulderX = sx(45);
      final double rightShoulderX = sx(105);
      
      final double pelvisY = pose == 'sitting' ? sy(130) : sy(130);
      final double pelvisLeftX = sx(48);
      final double pelvisRightX = sx(102);

      final double kneeY = pose == 'sitting' ? sy(175) : sy(180);
      final double leftKneeX = pose == 'sitting' ? sx(35) : sx(48);
      final double rightKneeX = pose == 'sitting' ? sx(115) : sx(102);

      final double footY = pose == 'sitting' ? sy(225) : sy(230);
      final double leftFootX = pose == 'sitting' ? sx(35) : sx(48);
      final double rightFootX = pose == 'sitting' ? sx(115) : sx(102);

      // --- Draw Reference Alignment Lines first (under the body layout) ---
      // 1. Neck Alignment Reference (vertical center line)
      drawDashedLine(
        Offset(sx(75), sy(15)), 
        Offset(sx(75), sy(80)), 
        neckError ? errorColor.withOpacity(0.3) : excellentColor.withOpacity(0.3)
      );

      // 2. Shoulder Alignment Reference (horizontal level line)
      drawDashedLine(
        Offset(sx(25), shoulderY), 
        Offset(sx(125), shoulderY), 
        (leftShoulderError || rightShoulderError) ? warningColor.withOpacity(0.3) : excellentColor.withOpacity(0.3)
      );

      // 3. Spine Alignment Reference (vertical center line)
      drawDashedLine(
        Offset(sx(75), shoulderY), 
        Offset(sx(75), pelvisY + sy(10)), 
        spineError ? errorColor.withOpacity(0.3) : excellentColor.withOpacity(0.3)
      );

      // 4. Pelvis Alignment Reference (horizontal level line)
      drawDashedLine(
        Offset(sx(25), pelvisY), 
        Offset(sx(125), pelvisY), 
        pelvisError ? errorColor.withOpacity(0.3) : excellentColor.withOpacity(0.3)
      );

      // 5. Knee Alignment Reference (horizontal level line)
      drawDashedLine(
        Offset(sx(25), kneeY), 
        Offset(sx(125), kneeY), 
        kneeError ? errorColor.withOpacity(0.3) : excellentColor.withOpacity(0.3)
      );

      // --- Draw Chair background contour if Sitting ---
      if (pose == 'sitting') {
        final Paint chairPaint = Paint()
          ..color = Colors.blueGrey.shade50
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        
        // Seat
        canvas.drawLine(Offset(sx(25), pelvisY + sy(3)), Offset(sx(110), pelvisY + sy(3)), chairPaint);
        // Backrest
        canvas.drawLine(Offset(sx(105), shoulderY - sy(10)), Offset(sx(105), pelvisY + sy(3)), chairPaint);
        // Legs
        canvas.drawLine(Offset(sx(35), pelvisY + sy(3)), Offset(sx(35), footY), chairPaint);
        canvas.drawLine(Offset(sx(105), pelvisY + sy(3)), Offset(sx(105), footY), chairPaint);
      }

      // --- Draw Static Limbs (Lower Arms, Lower Legs) in light gray ---
      linePaint.color = Colors.blueGrey.shade50;
      linePaint.strokeWidth = 4.0;
      
      // Left Lower Arm
      canvas.drawLine(Offset(leftShoulderX, shoulderY + sy(25)), Offset(leftShoulderX - sx(7), shoulderY + sy(55)), linePaint);
      // Right Lower Arm
      canvas.drawLine(Offset(rightShoulderX, shoulderY + sy(25)), Offset(rightShoulderX + sx(7), shoulderY + sy(55)), linePaint);
      
      // Left Lower Leg
      canvas.drawLine(Offset(leftKneeX, kneeY), Offset(leftFootX, footY), linePaint);
      // Right Lower Leg
      canvas.drawLine(Offset(rightKneeX, kneeY), Offset(rightFootX, footY), linePaint);

      // --- Draw Head & Neck ---
      final Color neckColor = getPartColor(neckError);
      fillPaint.color = neckColor;
      // Head circle
      canvas.drawCircle(Offset(sx(75), headY), sx(12), fillPaint);
      // Neck vertical line
      linePaint.color = neckColor;
      linePaint.strokeWidth = 6.0;
      canvas.drawLine(Offset(sx(75), headY + sy(12)), Offset(sx(75), neckEndY), linePaint);

      // --- Draw Shoulders ---
      // Left Shoulder
      linePaint.color = getPartColor(leftShoulderError, isWarning: true);
      linePaint.strokeWidth = 7.0;
      canvas.drawLine(Offset(sx(75), neckEndY), Offset(leftShoulderX, shoulderY), linePaint);
      // Right Shoulder
      linePaint.color = getPartColor(rightShoulderError, isWarning: true);
      canvas.drawLine(Offset(sx(75), neckEndY), Offset(rightShoulderX, shoulderY), linePaint);

      // --- Draw Upper Arms ---
      linePaint.color = Colors.blueGrey.shade100;
      linePaint.strokeWidth = 5.0;
      canvas.drawLine(Offset(leftShoulderX, shoulderY), Offset(leftShoulderX, shoulderY + sy(25)), linePaint);
      canvas.drawLine(Offset(rightShoulderX, shoulderY), Offset(rightShoulderX, shoulderY + sy(25)), linePaint);

      // --- Draw Spine / Torso ---
      linePaint.color = getPartColor(spineError);
      linePaint.strokeWidth = 8.0;
      canvas.drawLine(Offset(sx(75), neckEndY), Offset(sx(75), pelvisY), linePaint);

      // --- Draw Pelvis ---
      linePaint.color = getPartColor(pelvisError);
      linePaint.strokeWidth = 8.0;
      canvas.drawLine(Offset(pelvisLeftX, pelvisY), Offset(pelvisRightX, pelvisY), linePaint);

      // --- Draw Thighs ---
      linePaint.color = Colors.blueGrey.shade100;
      linePaint.strokeWidth = 6.0;
      canvas.drawLine(Offset(pelvisLeftX, pelvisY), Offset(leftKneeX, kneeY), linePaint);
      canvas.drawLine(Offset(pelvisRightX, pelvisY), Offset(rightKneeX, kneeY), linePaint);

      // --- Draw Knees ---
      final Color kneeColor = getPartColor(kneeError);
      fillPaint.color = kneeColor;
      canvas.drawCircle(Offset(leftKneeX, kneeY), sx(6), fillPaint);
      canvas.drawCircle(Offset(rightKneeX, kneeY), sx(6), fillPaint);

      // --- Draw outer highlights for selected parts ---
      if (selectedPart != null) {
        final Paint highlightPaint = Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        if (selectedPart == 'Neck') {
          canvas.drawCircle(Offset(sx(75), headY), sx(18), highlightPaint);
        } else if (selectedPart == 'Left Shoulder') {
          canvas.drawCircle(Offset(leftShoulderX, shoulderY), sx(12), highlightPaint);
        } else if (selectedPart == 'Right Shoulder') {
          canvas.drawCircle(Offset(rightShoulderX, shoulderY), sx(12), highlightPaint);
        } else if (selectedPart == 'Upper Back') {
          canvas.drawRect(Rect.fromLTRB(sx(65), neckEndY + sy(12), sx(85), pelvisY - sy(12)), highlightPaint);
        } else if (selectedPart == 'Pelvis') {
          canvas.drawRect(Rect.fromLTRB(pelvisLeftX - sx(8), pelvisY - sy(8), pelvisRightX + sx(8), pelvisY + sy(8)), highlightPaint);
        } else if (selectedPart == 'Left Knee') {
          canvas.drawCircle(Offset(leftKneeX, kneeY), sx(12), highlightPaint);
        } else if (selectedPart == 'Right Knee') {
          canvas.drawCircle(Offset(rightKneeX, kneeY), sx(12), highlightPaint);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in BodyMapPainter.paint: $e\n$stackTrace');
      final Paint paint = Paint()..color = Colors.red.withOpacity(0.2);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.selectedPart != selectedPart ||
        oldDelegate.isExcellent != isExcellent ||
        oldDelegate.neckError != neckError ||
        oldDelegate.leftShoulderError != leftShoulderError ||
        oldDelegate.rightShoulderError != rightShoulderError ||
        oldDelegate.spineError != spineError ||
        oldDelegate.pelvisError != pelvisError ||
        oldDelegate.kneeError != kneeError ||
        oldDelegate.pose != pose;
  }
}
