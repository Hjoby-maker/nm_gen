// lib/presentation/screens/person_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/media_attachment.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/presentation/blocs/event/event_bloc.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/media/media_bloc.dart';
import 'package:nm_gen/presentation/blocs/media/media_event.dart';
import 'package:nm_gen/presentation/blocs/media/media_state.dart';
import 'package:nm_gen/presentation/blocs/person/person_bloc.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/presentation/widgets/media_section.dart';
import 'package:nm_gen/presentation/widgets/person_detail/person_events_section.dart';
import 'package:nm_gen/presentation/widgets/person_detail/person_info_header.dart';
import 'package:nm_gen/presentation/widgets/person_form_dialog.dart';

/// Экран деталей человека. Оркестрирует три bloc'а (Person/Event/Media) и
/// две вкладки ("Информация" и "Файлы") - вся содержательная логика вынесена
/// в отдельные виджеты (person_detail/*), этот файл только связывает их.
class PersonDetailScreen extends StatefulWidget {
  const PersonDetailScreen({Key? key, required this.personId})
    : super(key: key);
  final String personId;

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen>
    with SingleTickerProviderStateMixin {
  Person? _person;
  bool _isLoading = true;
  String? _treeId;
  late TabController _tabController;

  late final PersonBloc _personBloc;
  late final EventBloc _eventBloc;
  late final MediaBloc _mediaBloc;

  @override
  void initState() {
    super.initState();
    _personBloc = getIt<PersonBloc>();
    _eventBloc = getIt<EventBloc>();
    _mediaBloc = getIt<MediaBloc>();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final personState = _personBloc.state;
    if (personState is! PersonsLoaded || personState.treeId != _treeId) {
      _personBloc.add(LoadPersonsEvent(treeId: _treeId));
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final updatedState = _personBloc.state;
    if (updatedState is PersonsLoaded) {
      setState(() {
        _person = updatedState.persons.firstWhere(
          (p) => p.id == widget.personId,
          orElse: () => Person.empty(),
        );
        _treeId = updatedState.treeId ?? 'default';
        _isLoading = false;
      });

      _eventBloc.add(LoadPersonEventsEvent(widget.personId, treeId: _treeId));
      // ⚠️ Раньше здесь ещё был _mediaBloc.add(LoadPrimaryPortrait(...)).
      // Он больше не нужен: PersonAvatar показывает фото из person.photoPath
      // (см. BlocListener ниже), а не напрямую из состояния MediaBloc. Но
      // этот вызов ВСЁ РАВНО обрабатывался - MediaBloc обрабатывает события
      // строго последовательно, и он шёл СРАЗУ ПОСЛЕ LoadMediaForPerson,
      // затирая MediaLoaded финальным состоянием PrimaryPortraitLoaded.
      // Вкладка "Файлы" (MediaSection) слушает тот же самый MediaBloc и не
      // знала, что делать с PrimaryPortraitLoaded - поэтому список файлов
      // пропадал сразу после загрузки экрана. Именно это и было багом.
      _mediaBloc.add(LoadMediaForPerson(personId: widget.personId));
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _personBloc),
        BlocProvider.value(value: _eventBloc),
        BlocProvider.value(value: _mediaBloc),
      ],
      child: BlocListener<MediaBloc, MediaState>(
        // ⚠️ PersonAvatar рисует фото из person.photoPath, а не из
        // MediaBloc (и не может из него читать напрямую - тот же виджет
        // используется в списках для разных людей одновременно, а у
        // MediaBloc только одно текущее состояние на весь bloc). Поэтому
        // здесь, как только основной портрет успешно сохранён или
        // назначен, синхронизируем photoPath на самом Person - именно
        // это поле PersonAvatar показывает везде в приложении.
        listener: (context, state) {
          MediaAttachment? updatedPortrait;
          if (state is MediaFileAdded && state.media.isPrimary) {
            updatedPortrait = state.media;
          } else if (state is MediaUpdated && state.media.isPrimary) {
            updatedPortrait = state.media;
          }

          if (updatedPortrait != null &&
              updatedPortrait.personId == widget.personId &&
              _person != null) {
            final Person updatedPerson = _person!.copyWith(
              photoPath: updatedPortrait.localPath,
            );
            _personBloc.add(UpdatePersonEvent(updatedPerson));
            setState(() {
              _person = updatedPerson;
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_person?.displayName ?? 'Загрузка...'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Информация'),
                Tab(icon: Icon(Icons.folder), text: 'Файлы'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _person != null && _person!.id.isNotEmpty
                    ? () => _showEditPersonDialog(context)
                    : null,
                tooltip: 'Редактировать',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _person == null || _person!.id.isEmpty
              ? _buildNotFoundView()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildInfoTab(), _buildMediaTab()],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PersonInfoHeader(person: _person!),
          const SizedBox(height: 24),
          PersonEventsSection(
            personId: widget.personId,
            treeId: _treeId ?? 'default',
            mediaBloc: _mediaBloc,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MediaSection(
        personId: widget.personId,
        showPrimaryBadge: true,
        mediaBloc: _mediaBloc,
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Человек не найден',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  void _showEditPersonDialog(BuildContext context) {
    if (_person == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => PersonFormDialog(
        existingPerson: _person!,
        treeId: _treeId ?? 'default',
        onSave: (updatedPerson) {
          _personBloc.add(UpdatePersonEvent(updatedPerson));
          setState(() {
            _person = updatedPerson;
          });
        },
      ),
    );
  }
}
