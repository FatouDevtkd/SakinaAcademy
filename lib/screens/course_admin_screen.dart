import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sakina_ac/admin_access.dart';
import 'package:sakina_ac/screens/media_player_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

const _mediaTypes = <String, List<String>>{
  'video': ['mp4', 'mov', 'm4v', 'webm'],
  'audio': ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
  'pdf': ['pdf'],
};
const _maxUploadBytes = 100 * 1024 * 1024;

String _contentTypeFor(String extension) {
  switch (extension) {
    case 'mp4':
    case 'm4v':
      return 'video/mp4';
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return 'video/webm';
    case 'mp3':
      return 'audio/mpeg';
    case 'm4a':
      return 'audio/mp4';
    case 'aac':
      return 'audio/aac';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
      return 'audio/ogg';
    case 'pdf':
      return 'application/pdf';
    default:
      throw ArgumentError.value(extension, 'extension', 'Unsupported file');
  }
}

class CourseManagerScreen extends StatelessWidget {
  const CourseManagerScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _courses =>
      FirebaseFirestore.instance.collection('courses');

  Future<void> _createCourse(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'video';
    XFile? selectedFile;
    var uploading = false;
    double? progress;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !uploading,
          child: AlertDialog(
            title: const Text('Ajouter un cours'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(labelText: 'Titre du cours'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Format'),
                      items: const [
                        DropdownMenuItem(value: 'video', child: Text('Vidéo')),
                        DropdownMenuItem(value: 'audio', child: Text('Audio')),
                        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      ],
                      onChanged: uploading
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => type = value);
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: uploading
                          ? null
                          : () async {
                              final extensions = _mediaTypes[type]!;
                              final file = await openFile(
                                acceptedTypeGroups: [
                                  XTypeGroup(
                                    label: type,
                                    extensions: extensions,
                                  ),
                                ],
                              );
                              if (file != null) {
                                setDialogState(() => selectedFile = file);
                              }
                            },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFile?.name ?? 'Choisir un fichier'),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text('${(progress! * 100).round()} % envoyé'),
                    ],
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Formats vidéo : MP4, MOV, M4V, WebM. Audio : MP3, M4A, AAC, WAV, OGG. PDF accepté. Taille maximale : 100 Mo.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    uploading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: uploading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty || selectedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Saisissez un titre et choisissez un fichier.'),
                            ),
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        if (!isSakinaAdmin(user)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Accès réservé aux administratrices vérifiées.'),
                            ),
                          );
                          return;
                        }

                        final fileExtension =
                            selectedFile!.name.split('.').last.toLowerCase();
                        if (!(_mediaTypes[type]?.contains(fileExtension) ??
                            false)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'L’extension du fichier ne correspond pas au format choisi.'),
                            ),
                          );
                          return;
                        }

                        final bytes = await selectedFile!.readAsBytes();
                        if (!context.mounted) return;
                        if (bytes.length > _maxUploadBytes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Le fichier dépasse la limite de 100 Mo.'),
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          uploading = true;
                          progress = 0;
                        });
                        final course = _courses.doc();
                        final storagePath =
                            'courses/${course.id}/${const Uuid().v4()}.$fileExtension';
                        final fileRef =
                            FirebaseStorage.instance.ref(storagePath);
                        try {
                          final uploadTask = fileRef.putData(
                            bytes,
                            SettableMetadata(
                              contentType: _contentTypeFor(fileExtension),
                            ),
                          );
                          await for (final snapshot
                              in uploadTask.snapshotEvents) {
                            if (dialogContext.mounted &&
                                snapshot.totalBytes > 0) {
                              setDialogState(
                                () => progress = snapshot.bytesTransferred /
                                    snapshot.totalBytes,
                              );
                            }
                          }
                          await uploadTask;
                          final downloadUrl = await fileRef.getDownloadURL();
                          await course.set({
                            'title': title,
                            'description': descriptionController.text.trim(),
                            'type': type,
                            'downloadUrl': downloadUrl,
                            'storagePath': storagePath,
                            'published': false,
                            'createdBy': user!.uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cours ajouté en brouillon. Publiez-le pour le rendre visible aux étudiantes.'),
                              ),
                            );
                          }
                        } catch (error) {
                          try {
                            await fileRef.delete();
                          } on FirebaseException catch (cleanupError) {
                            if (cleanupError.code != 'object-not-found') {
                              debugPrint(
                                  'Échec du nettoyage après erreur : $cleanupError');
                            }
                          }
                          if (dialogContext.mounted) {
                            setDialogState(() => uploading = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Échec du dépôt du cours : $error')),
                            );
                          }
                        }
                      },
                child: uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Déposer'),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _setPublished(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> course,
    bool published,
  ) async {
    try {
      await course.reference.update({
        'published': published,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Impossible de modifier la publication : ${error.message ?? error.code}')),
        );
      }
    }
  }

  Future<void> _deleteCourse(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce cours ?'),
        content: const Text(
            'Le fichier et les questionnaires associés seront supprimés définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final quizzes = await course.reference.collection('quizzes').get();
      for (final quiz in quizzes.docs) {
        await quiz.reference.delete();
      }
      final path = course.data()['storagePath'] as String?;
      if (path != null) {
        await FirebaseStorage.instance.ref(path).delete();
      }
      await course.reference.delete();
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Impossible de supprimer le cours : ${error.message ?? error.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les cours')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCourse(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Déposer un cours'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _courses.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child:
                  Text('Impossible de charger les cours : ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('Aucun cours. Déposez le premier.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final course = snapshot.data!.docs[index];
              final data = course.data();
              final published = data['published'] == true;
              final type = data['type'] as String? ?? '';
              return Card(
                child: ListTile(
                  leading: Icon(
                    type == 'video'
                        ? Icons.video_library_outlined
                        : type == 'audio'
                            ? Icons.audiotrack
                            : Icons.picture_as_pdf_outlined,
                  ),
                  title: Text(data['title'] as String? ?? 'Cours sans titre'),
                  subtitle: Text(
                    '${type.toUpperCase()} · ${published ? 'Publié' : 'Brouillon'}',
                  ),
                  isThreeLine:
                      (data['description'] as String? ?? '').isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'publish') {
                        _setPublished(context, course, !published);
                      } else if (action == 'delete') {
                        _deleteCourse(context, course);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'publish',
                        child: Text(published ? 'Dépublier' : 'Publier'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class QuizManagerScreen extends StatelessWidget {
  const QuizManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaires de compréhension')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, coursesSnapshot) {
          if (coursesSnapshot.hasError) {
            return Center(
              child: Text(
                  'Impossible de charger les cours : ${coursesSnapshot.error}'),
            );
          }
          if (!coursesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = coursesSnapshot.data!.docs;
          if (courses.isEmpty) {
            return const Center(child: Text('Déposez d’abord un cours.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final course in courses) _AdminCourseQuizzes(course: course),
            ],
          );
        },
      ),
    );
  }
}

class _AdminCourseQuizzes extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> course;

  const _AdminCourseQuizzes({required this.course});

  Future<void> _newQuiz(BuildContext context) async {
    final titleController = TextEditingController();
    final questions = [_QuestionDraft()];
    var publishing = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Créer un questionnaire'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 12),
                  for (var questionIndex = 0;
                      questionIndex < questions.length;
                      questionIndex++) ...[
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Question ${questionIndex + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (questions.length > 1)
                          IconButton(
                            tooltip: 'Retirer la question',
                            onPressed: publishing
                                ? null
                                : () => setDialogState(
                                      () => questions.removeAt(questionIndex),
                                    ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    TextField(
                      controller: questions[questionIndex].prompt,
                      decoration: const InputDecoration(labelText: 'Question'),
                      maxLines: 2,
                    ),
                    for (var optionIndex = 0;
                        optionIndex < questions[questionIndex].options.length;
                        optionIndex++)
                      TextField(
                        controller:
                            questions[questionIndex].options[optionIndex],
                        decoration: InputDecoration(
                          labelText:
                              'Réponse ${String.fromCharCode(65 + optionIndex)}',
                        ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: questions[questionIndex].correctOption,
                      decoration:
                          const InputDecoration(labelText: 'Bonne réponse'),
                      items: List.generate(
                        4,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text(
                            'Réponse ${String.fromCharCode(65 + index)}',
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(
                            () =>
                                questions[questionIndex].correctOption = value,
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: publishing || questions.length >= 50
                        ? null
                        : () => setDialogState(
                              () => questions.add(_QuestionDraft()),
                            ),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une question'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: publishing ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: publishing
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty ||
                          questions.any(
                            (question) =>
                                question.prompt.text.trim().isEmpty ||
                                question.options.any(
                                  (option) => option.text.trim().isEmpty,
                                ),
                          )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Complétez le titre, la question et les quatre réponses.'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => publishing = true);
                      try {
                        await course.reference.collection('quizzes').add({
                          'title': title,
                          'questions': questions
                              .map(
                                (question) => {
                                  'prompt': question.prompt.text.trim(),
                                  'options': question.options
                                      .map((option) => option.text.trim())
                                      .toList(),
                                  'correctOption': question.correctOption,
                                },
                              )
                              .toList(),
                          'published': false,
                          'createdBy': FirebaseAuth.instance.currentUser!.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } on FirebaseException catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => publishing = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Impossible de créer le questionnaire : ${error.message ?? error.code}'),
                            ),
                          );
                        }
                      }
                    },
              child: publishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer le brouillon'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    for (final question in questions) {
      question.dispose();
    }
  }

  Future<void> _togglePublished(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> quiz,
  ) async {
    try {
      await quiz.reference.update({
        'published': quiz.data()['published'] != true,
      });
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Impossible de modifier le questionnaire : ${error.message ?? error.code}'),
          ),
        );
      }
    }
  }

  Future<void> _deleteQuiz(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> quiz,
  ) async {
    try {
      await quiz.reference.delete();
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible de supprimer le questionnaire : ${error.message ?? error.code}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = course.reference
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(course.data()['title'] as String? ?? 'Cours'),
              trailing: IconButton(
                tooltip: 'Ajouter un questionnaire',
                onPressed: () => _newQuiz(context),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: quizzes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Erreur de chargement : ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Aucun questionnaire pour ce cours.'),
                  );
                }
                return Column(
                  children: [
                    for (final quiz in snapshot.data!.docs)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(
                            quiz.data()['title'] as String? ?? 'Questionnaire'),
                        subtitle: Text(
                          quiz.data()['published'] == true
                              ? 'Publié'
                              : 'Brouillon',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: quiz.data()['published'] == true,
                              onChanged: (_) => _togglePublished(context, quiz),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteQuiz(context, quiz),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  final prompt = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  int correctOption = 0;

  void dispose() {
    prompt.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class PublishedCoursesSection extends StatelessWidget {
  const PublishedCoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('published', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(
                  'Impossible de charger les nouveaux cours : ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nouveaux cours',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final course in snapshot.data!.docs)
              Card(
                child: ListTile(
                  leading: Icon(
                    course.data()['type'] == 'video'
                        ? Icons.video_library_outlined
                        : course.data()['type'] == 'audio'
                            ? Icons.audiotrack
                            : Icons.picture_as_pdf_outlined,
                  ),
                  title: Text(course.data()['title'] as String? ?? 'Cours'),
                  subtitle: Text(
                    course.data()['description'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublishedCourseScreen(course: course),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PublishedCourseScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> course;

  const PublishedCourseScreen({super.key, required this.course});

  Future<void> _openContent(BuildContext context) async {
    final data = course.data();
    final type = data['type'] as String? ?? '';
    final url = data['downloadUrl'] as String? ?? '';
    if (type == 'video' || type == 'audio') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaPlayerScreen(
            title: data['title'] as String? ?? 'Cours',
            mediaUrl: url,
            isVideo: type == 'video',
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le PDF.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = course.data();
    final title = data['title'] as String? ?? 'Cours';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(data['description'] as String? ?? ''),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openContent(context),
            icon: const Icon(Icons.play_arrow),
            label:
                Text(data['type'] == 'pdf' ? 'Ouvrir le PDF' : 'Lire le cours'),
          ),
          const SizedBox(height: 24),
          Text(
            'Questionnaires de compréhension',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: course.reference
                .collection('quizzes')
                .where('published', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                    'Impossible de charger les questionnaires : ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aucun questionnaire publié pour le moment.'),
                );
              }
              return Column(
                children: [
                  for (final quiz in snapshot.data!.docs)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.quiz_outlined),
                        title: Text(
                            quiz.data()['title'] as String? ?? 'Questionnaire'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(quiz: quiz),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, int> _answers = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.quiz.data();
    final title = data['title'] as String? ?? 'Questionnaire';
    final questions = (data['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final score = questions.indexed
        .where((entry) => _answers[entry.$1] == entry.$2['correctOption'])
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var index = 0; index < questions.length; index++)
            _QuizQuestionCard(
              index: index,
              question: questions[index],
              selectedOption: _answers[index],
              showAnswer: _submitted,
              onSelected: _submitted
                  ? null
                  : (option) => setState(() => _answers[index] = option),
            ),
          if (_submitted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Résultat : $score / ${questions.length}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: _submitted || _answers.length != questions.length
                ? null
                : () => setState(() => _submitted = true),
            child: Text(
                _submitted ? 'Questionnaire terminé' : 'Voir mon résultat'),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final int? selectedOption;
  final bool showAnswer;
  final ValueChanged<int>? onSelected;

  const _QuizQuestionCard({
    required this.index,
    required this.question,
    required this.selectedOption,
    required this.showAnswer,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = (question['options'] as List<dynamic>? ?? [])
        .map((option) => option.toString())
        .toList();
    final correctOption = question['correctOption'] as int?;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question['prompt'] as String? ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (var option = 0; option < options.length; option++)
              RadioListTile<int>(
                value: option,
                groupValue: selectedOption,
                onChanged:
                    onSelected == null ? null : (_) => onSelected!(option),
                title: Text(options[option]),
                secondary: showAnswer && option == correctOption
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
