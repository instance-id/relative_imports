/*
-----------------------------------------------------
-- instance.id - 6/2020                            --
-- Created by Dan - http://instance.id             --
-- https://github.com/instance-id/relative_imports --
-----------------------------------------------------
 */
import 'dart:io' as io;
import 'package:glob/glob.dart';

import 'package:args/args.dart';
import 'package:codemod/codemod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_span/source_span.dart';

const fileName = 'file-name';
const directoryPath = 'directory-path';
const pubspecLocation = 'pubspec-location';
const autoApply = 'auto-apply';
const verbose = 'verbose';

const pubspecFileName = 'pubspec.yaml';

// -----------------------------------------------------------------
// -- Set up logging parameters                                   --
Logger log = Logger(
    level: Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 55,
      lineLength: 100,
      colors: io.stdout.supportsAnsiEscapes,
      printEmojis: false,
      printTime: true,
    ));

ArgResults argResults;
String projectRoot;
String filePath;
String libPath;
io.File pubspecFile;
RegExp pattern;
Pubspec project;

void setupLogger(Level logLevel) {
  log = Logger(
      level: logLevel,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 55,
        lineLength: 100,
        colors: io.stdout.supportsAnsiEscapes,
        printEmojis: false,
        printTime: true,
      ));
}

// -----------------------------------------------------------------
// -- Get details about the current project                       --
Future<dynamic> _getPackageInfo({String pPath}) async {
  log.d('Argument Path: ${pPath}');
  (pPath != null) // Check again if provided path contains data   --
      // Path already contains pubspec?                           --
      ? (pPath.contains(pubspecFileName))
          ? () {
              // If so, assign pubspec path                       --
              pubspecFile = io.File(p.join(pPath));

              // Split path into segments, remove pubspec.yaml    --
              // from path list, recombine path segments          --
              // then assign to project root                      --
              var splitPath = p.split(pPath);
              splitPath.removeLast();
              projectRoot = p.joinAll(splitPath);
            }()
          : () {
              // If path doesn't contains 'pubspec.yaml' then     --
              // assign the project path, add pubspec.yaml        --
              // and assign to pubspecFile                        --
              projectRoot = pPath;
              pubspecFile = io.File(p.join(projectRoot, pubspecFileName));
            }()
      // If provided path is null, check if pubspec.yaml          --
      // exists in the current working directory                  --
      : pubspecFile = io.File(p.join(io.Directory.current.path, pubspecFileName));

  pubspecFile ??
      () {
        log.e('pubspec.yaml could not be found. Make sure you are either passing in your '
            'projects root directory, or using it as your projects current working directory.');
        return;
      }();

  log.d('pubspecFile: ${pubspecFile}');
  projectRoot = projectRoot.replaceAll(RegExp(r'\\'), '/');
  log.d('projectRoot: ${projectRoot}');

  return Pubspec.parse(await pubspecFile.readAsString());
}

void main(List<String> arguments) async {
  io.exitCode = 0;

  // ---------------------------------------------------------------
  // -- Possible arguments to be accepted                         --
  final parser = ArgParser()
    ..addOption(
      fileName,
      defaultsTo: null,
      abbr: 'f',
      help: 'The name of the .dart file in which to convert imports to relative',
    )
    ..addOption(
      directoryPath,
      defaultsTo: null,
      abbr: 'd',
      help: '1) Project root directory (1 or 2 Required)',
    )
    ..addOption(
      pubspecLocation,
      defaultsTo: 'pubspec.yaml',
      abbr: 'p',
      help: '2) The path to your projects pubspec.yaml (1 or 2 Required)',
    )
    ..addFlag(
      autoApply,
      defaultsTo: false,
      abbr: 'y',
      help: 'If -y argument is set, automatically apply all import changes. Otherwise you will be prompted '
          'to confirm the changes (Accept change (y = yes, n = no [default], A = yes to all, q = quit))',
    )
    ..addFlag(
      verbose,
      defaultsTo: false,
      abbr: 'v',
      help: 'If -v argument is set, additional log messages will be shown',
    );

  // ---------------------------------------------------------------
  // -- Parse Arguments passed from command line                  --
  argResults = parser.parse(arguments);
  setupLogger((argResults[verbose]) ? Level.debug : Level.warning);
  // ---------------------------------------------------------------
  // If project root is not provided, use pubspec file location   --
  final usePath = argResults[directoryPath] ?? argResults[pubspecLocation];
  log.d('usePath: ${usePath}');

  // ---------------------------------------------------------------
  // -- Determine if necessary arguments were provided, if not,   --
  // -- return error message                                      --
  if (usePath == null) {
    log.w('Either Directory Path (-d) or Pubspec Path (-p) required');
    return;
  }
  if (argResults[fileName] == null) {
    log.w('Filename (-f) in which to convert import paths is required');
    return;
  }

  filePath = argResults[fileName];

  // ---------------------------------------------------------------
  // -- Using provided arguments, determine project name          --
  // -- which will be used to locate package imports              --
  project = await _getPackageInfo(pPath: usePath);

  // ---------------------------------------------------------------
  // Regex pattern used to locate package imports                 --
  // https://github.com/luanpotter/vscode-dart-import/blob/fb7861b8e2d04e9d5f71e67fa21a1733463d3a96/src/main.ts#L50
  pattern = RegExp('''^\\s*import\\s*(['"])package:${project.name}/([^'"]*)['"]([^;]*);\\s*\$''', multiLine: true);

  // ---------------------------------------------------------------
  // -- Get file path as Glob so as to help with cross platform   --
  // -- compatibility                                             --
  libPath = p.join(projectRoot, 'lib');
  final dartFile = Glob('**$filePath.dart', caseSensitive: true, context: p.Context(style: p.Style.windows, current: libPath));

  io.exitCode = runInteractiveCodemod(
    filePathsFromGlob(dartFile),
    RegexSubstituter(),
    // If -y flag was passed auto apply all changes               --
    args: [(argResults[autoApply]) ? '--yes-to-all' : ''],
  );
}

// -----------------------------------------------------------------
// -- Using CodeMod package to make and apply patches to code     --
class RegexSubstituter implements Suggestor {
  @override
  bool shouldSkip(String sourceFileContents) => false;

  @override
  Iterable<Patch> generatePatches(SourceFile sourceFile) sync* {
    final contents = sourceFile.getText(0);
    log.d('Contents: ${contents}');
    for (final match in pattern.allMatches(contents)) {
      final line = match.group(0);
      final constraint = match.group(2);
      final newPath = "import '${p.relative(
        (p.join(libPath, constraint)),
        from: sourceFile.url.toFilePath(),
      )}';";
      final fixDelimiter = newPath.replaceAll(RegExp(r'\\'), '/');
      final fixRelative = fixDelimiter.replaceFirst('../', '');
      final updated = line.replaceFirst(line, fixRelative);

      yield Patch(
        sourceFile,
        sourceFile.span(match.start, match.end),
        updated,
      );
    }
  }
}
