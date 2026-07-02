// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../data/datasources/local/database/db_helper.dart' as _i131;
import '../data/datasources/local/family_local_datasource.dart' as _i586;
import '../data/datasources/local/person_local_datasource.dart' as _i809;
import '../data/repositories/family_repository_impl.dart' as _i70;
import '../data/repositories/person_repository_impl.dart' as _i672;
import '../domain/repositories/family_repository.dart' as _i1;
import '../domain/repositories/person_repository.dart' as _i1058;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt $initGetIt({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i131.DatabaseHelper>(() => _i131.DatabaseHelper());
    gh.factory<_i586.FamilyLocalDataSource>(
      () => _i586.FamilyLocalDataSource(gh<_i131.DatabaseHelper>()),
    );
    gh.factory<_i809.PersonLocalDataSource>(
      () => _i809.PersonLocalDataSource(gh<_i131.DatabaseHelper>()),
    );
    gh.factory<_i1058.PersonRepository>(
      () => _i672.PersonRepositoryImpl(gh<_i809.PersonLocalDataSource>()),
    );
    gh.factory<_i1.FamilyRepository>(
      () => _i70.FamilyRepositoryImpl(gh<_i586.FamilyLocalDataSource>()),
    );
    return this;
  }
}
