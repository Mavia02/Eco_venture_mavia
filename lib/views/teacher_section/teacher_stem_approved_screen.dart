import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/teacher_student_detail/teacher_student_detail_provider.dart';

class TeacherStemApprovedScreen extends ConsumerWidget {
  const TeacherStemApprovedScreen({super.key, required this.data});

  final Map<String, dynamic> data;
  factory TeacherStemApprovedScreen.fromGoRouterExtra(dynamic extra) {
    if (extra is Map<String, dynamic>) {
      return TeacherStemApprovedScreen(data: extra);
    }
    throw Exception(
      "TeacherStemApprovedScreen: missing or invalid route extra data",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = data['activity'] as Map<String, dynamic>;
    final submission = activity['data'] as Map<String, dynamic>;
    final String studentId = data['studentId'];

    final String status = submission['status'] ?? 'pending';

    ///  Collect ALL images safely
    final List<String> images = [];

    final raw = submission['proofImageUrls'] ?? submission['proof_image_urls'];
    if (raw is List) {
      images.addAll(raw.map((e) => e.toString()));
    } else if (raw is String) {
      images.add(raw);
    }

    final TextEditingController feedbackCtrl = TextEditingController();
    final TextEditingController pointsCtrl = TextEditingController(text: "50");

    return Scaffold(
      appBar: AppBar(

        leading: GestureDetector(
           onTap: () {
             context.goNamed('bottomNavTeacher');
           },
          child: Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text("STEM Submission Review"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              submission['challenge_title'] ?? 'STEM Challenge',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),


            Text(
              "Days Taken: ${submission['days_taken'] ?? 'N/A'}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            if (images.isNotEmpty) ...[
              Text(
                "Uploaded Proof",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  );
                },
              ),
            ] else
              const Center(child: Text("No images uploaded")),

            const SizedBox(height: 24),

            if (status != 'pending') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Status: ${status.toUpperCase()}",
                  style: TextStyle(
                    color: status == 'approved' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[

              const Text("Award Points"),
              const SizedBox(height: 8),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              const Text("Feedback"),
              const SizedBox(height: 8),
              TextField(controller: feedbackCtrl, maxLines: 3),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        ref
                            .read(
                              teacherStudentDetailViewModelProvider.notifier,
                            )
                            .markStemSubmission(
                              studentId: studentId,
                              challengeId: submission['challenge_id']
                                  .toString(),
                              approved: false,
                              points: 0,
                              feedback: feedbackCtrl.text.isEmpty
                                  ? "Try again"
                                  : feedbackCtrl.text,
                            );
                        context.goNamed('bottomNavTeacher');
                      },
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        ref
                            .read(
                              teacherStudentDetailViewModelProvider.notifier,
                            )
                            .markStemSubmission(
                              studentId: studentId,
                              challengeId: submission['challenge_id']
                                  .toString(),
                              approved: true,
                              points: int.tryParse(pointsCtrl.text) ?? 50,
                              feedback: feedbackCtrl.text.isEmpty
                                  ? "Great work!"
                                  : feedbackCtrl.text,
                            );
                        context.goNamed('bottomNavTeacher');
                      },
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
