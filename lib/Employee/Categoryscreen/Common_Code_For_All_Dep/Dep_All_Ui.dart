import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Editdailytaskreport.dart'; // adjust import if needed
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportCardWidget {
  static Widget buildReportCard(BuildContext context, Map<String, dynamic> task, String docId) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89),
                Color(0xFF0F52BA),
                Color(0xFF002147),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Employee Information"),
              const Divider(color: Colors.white),
              _buildTaskDetail('Employee ID', task['employeeId']),
              _buildTaskDetail('Employee Name', task['employeeName']),
              _buildTaskDetail('Department', task['Service_department']),
              // _buildTaskDetail('Location', task['location']),
              const SizedBox(height: 10),
              _buildSectionTitle("Task Details"),
              const Divider(color: Colors.white),
              // _buildTaskDetail('Task Title', task['taskTitle']),
              // _buildTaskDetail('Service Status', task['service_status']),
              _buildTaskDetail(
                'Submitted Date',
                task['date'] != null
                    ? DateFormat('dd MMM yyyy').format((task['date'] as Timestamp).toDate())
                    : '',
              ),
              // _buildTaskDetail('Actions Taken', task['actionsTaken']),
              // _buildTaskDetail('Next Steps', task['nextSteps']),
              const SizedBox(height: 10),

              _buildSectionTitle("Work Log"),
              const Divider(color: Colors.white),
              const SizedBox(height: 5),
              if (task['workLog'] != null)
                ...List<Widget>.from((task['workLog'] as List).map(
                      (log) => _buildTaskDetail(log['timeSlot'], log['description']),
                )),
              const SizedBox(height: 10),

              if (task['uploadedFiles'] != null &&
                  task['uploadedFiles'] is List &&
                  task['uploadedFiles'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Attached Files"),
                    const Divider(color: Colors.white),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: task['uploadedFiles'].length,
                        itemBuilder: (context, index) {
                          final file = task['uploadedFiles'][index];
                          final String url = file['downloadUrl'] ?? '';
                          final String fileType =
                          (file['fileType'] ?? '').toLowerCase();
                          final String fileName = file['fileName'] ?? 'Unnamed';
                          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                              .contains(fileType);

                          return GestureDetector(
                            onTap: () async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(color: Colors.tealAccent),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: isImage
                                        ? Image.network(
                                      url,
                                      width: 100,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
                                    )
                                        : Icon(
                                      fileType == 'pdf'
                                          ? Icons.picture_as_pdf
                                          : Icons.insert_drive_file,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditAllTaskOfReports(
                          docId: docId,
                          reportData: task,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTaskDetail(String title, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox();
    final icon = _getIconForTitle(title);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, color: Colors.cyanAccent, size: 18),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'employee id':
        return Icons.badge;
      case 'employee name':
        return Icons.person;
      case 'task title':
        return Icons.assignment;
      case 'department':
      case 'service_department':
        return Icons.account_tree;
      case 'service status':
        return Icons.verified;
      case 'location':
        return Icons.location_on;
      case 'submitted date':
      case 'submitteddate':
      case 'date':
        return Icons.calendar_today;
      case 'actions taken':
        return Icons.build_circle;
      case 'next steps':
        return Icons.trending_up;
      case 'work log':
        return Icons.work_history;
      case 'attached files':
        return Icons.attach_file;
      case 'time slot':
        return Icons.access_time;
      case 'description':
        return Icons.notes;
      default:
        return Icons.info_outline;
    }
  }
}
