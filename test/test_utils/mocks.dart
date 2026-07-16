// test/test_utils/mocks.dart
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/project_repository.dart';
import 'package:nm_gen/domain/repositories/media_repository.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/project_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/event_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/media_local_datasource.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockMediaRepository extends Mock implements MediaRepository {}

class MockPersonLocalDataSource extends Mock implements PersonLocalDataSource {}

class MockFamilyLocalDataSource extends Mock implements FamilyLocalDataSource {}

class MockProjectLocalDataSource extends Mock
    implements ProjectLocalDataSource {}

class MockEventLocalDataSource extends Mock implements EventLocalDataSource {}

class MockMediaLocalDataSource extends Mock implements MediaLocalDataSource {}
