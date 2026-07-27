import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onLaunchDashboard;

  const LandingPage({super.key, required this.onLaunchDashboard});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _contactFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'Is my camera feed secure and private?',
      'answer': 'Absolutely. Posture Fix Pro leverages browser-side vision algorithms. No camera frames are streamed, stored, or processed on external servers.'
    },
    {
      'question': 'What is the 10-Second Monitoring Mode?',
      'answer': 'It is a quick alignment check. The system counts down for 10 seconds, tracks your ear and shoulder coordinates, and scores your neutral alignment.'
    },
    {
      'question': 'Do I need any specialized camera hardware?',
      'answer': 'No. Any standard built-in laptop camera or plug-and-play USB webcam works perfectly.'
    }
  ];

  int _expandedFaqIndex = -1;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0B2917),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.run_circle_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'PostureFixPro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0B2917),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isMobile) ...[
            TextButton(onPressed: () {}, child: const Text('Features', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () {}, child: const Text('FAQ', style: TextStyle(color: Colors.grey))),
            const SizedBox(width: 12),
          ],
          ElevatedButton(
            onPressed: widget.onLaunchDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Launch Dashboard'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 64,
                vertical: 64,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFECFDF5), Colors.white],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildHeroContent(context, true),
                    )
                  : Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildHeroContent(context, false),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 4,
                          child: _buildHeroImage(),
                        ),
                      ],
                    ),
            ),

            // Features Grid Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Everything for perfect posture',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B2917),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeatureCard(
                        Icons.camera_alt_outlined,
                        'Webcam Tracking',
                        'Tracks body coordinates locally in the web browser with zero video stream upload.',
                      ),
                      _buildFeatureCard(
                        Icons.insights_outlined,
                        'Biometric Analysis',
                        'Calculates forward neck slouch deviations and horizontal shoulder tilt parameters.',
                      ),
                      _buildFeatureCard(
                        Icons.notifications_active_outlined,
                        'Slouch Alert Tone',
                        'Plays audio chime alerts immediately when poor alignment is held for >1.5 seconds.',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // FAQ Section
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'FAQ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B2917),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _faqItems.length,
                      itemBuilder: (context, index) {
                        final isExpanded = _expandedFaqIndex == index;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  _faqItems[index]['question']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B2917),
                                  ),
                                ),
                                trailing: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: const Color(0xFF0B2917),
                                ),
                                onTap: () {
                                  setState(() {
                                    _expandedFaqIndex = isExpanded ? -1 : index;
                                  });
                                },
                              ),
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _faqItems[index]['answer']!,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Contact Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _contactFormKey,
                  child: Column(
                    children: [
                      const Text(
                        'Contact Support',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B2917),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Email required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Message required' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_contactFormKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message sent successfully! Our team will contact you.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                            _nameController.clear();
                            _emailController.clear();
                            _messageController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B2917),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Send Message'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              color: const Color(0xFF0B2917),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Center(
                child: Text(
                  '© 2026 Posture Fix Pro. Built with Flutter Web & Flask.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeroContent(BuildContext context, bool isMobile) {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '🌟 Real-Time AI Posture Assistant',
          style: TextStyle(
            color: Color(0xFF047857),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Fix Your Posture,\nBoost Your Focus.',
        style: TextStyle(
          fontSize: isMobile ? 36 : 48,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0B2917),
          height: 1.2,
        ),
        textAlign: isMobile ? TextAlign.center : TextAlign.start,
      ),
      const SizedBox(height: 16),
      Text(
        'Optimize your ergonomic sitting alignment using computer vision. Get instant webcam reminders, detailed reports, and structured recovery analytics.',
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        textAlign: isMobile ? TextAlign.center : TextAlign.start,
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: widget.onLaunchDashboard,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start Monitoring Free'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    ];
  }

  Widget _buildHeroImage() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 300,
          color: const Color(0xFFF3F4F6),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 96,
                  color: Color(0xFF10B981),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shoulder Tilt: Stable'),
                      Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B2917),
            ),
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
