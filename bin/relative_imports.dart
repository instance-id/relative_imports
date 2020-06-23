/*
-----------------------------------------------------
-- instance.id - 6/2020                            --
-- Created by Dan - http://instance.id             --
-- https://github.com/instance-id/relative_imports --
-----------------------------------------------------
 */
import 'dart:io';
import 'package:glob/glob.dart';

import 'package:args/args.dart';
import 'package:codemod/codemod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_span/source_span.dart';
import 'package:dartx/dartx_io.dart';

const fileLocation = 'file-location';
const directoryPath = 'directory-path';
const pubspecLocation = 'pubspec-location';
const autoApply = 'auto-apply';
const verbose = 'verbose';
const pubspecFileName = 'pubspec.yaml';

Logger log;
ArgResults argResults;
String projectRoot;
File filePath;
String libPath;
File pubspecFile;
RegExp pattern;
Pubspec project;

// -----------------------------------------------------------------
// -- Set up logging parameters                                   --
void setupLogger(Level logLevel) {
  log = Logger(
      level: logLevel,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 55,
        lineLength: 100,
        colors: stdout.supportsAnsiEscapes,
        printEmojis: false,
        printTime: true,
      ));
}

const pubSpecNotFound = 'pubspec.yaml could not be found. \n Ensure you are either passing in your '
    'the absolute path to the file, or the path to your projects root directory to the $pubspecLocation (-p) flag.\n '
    '(ex. -p path/to/project/pubspec.yaml) or (ex. -p path/to/project) \n';

// -----------------------------------------------------------------
// -- Pubspec file was included path                              --
// -- Split path into segments, remove pubspec.yaml               --
// -- from path list, recombine path segments                     --
// -- then assign to project root                                 --
Future<File> _pubspecInPath(String pPath) async {
  var splitPath = p.split(pPath);
  splitPath.removeLast();
  projectRoot = p.joinAll(splitPath);
  return File(p.join(pPath));
}

// -----------------------------------------------------------------
// -- Pubspec file was not included path                          --
// -- If path doesn't contains 'pubspec.yaml' then                --
// -- assign the project path, add pubspec.yaml                   --
// -- and assign to pubspecFile                                   --
Future<File> _pubspecNotInPath(String pPath) async {
  projectRoot = pPath;
  return File(p.join(projectRoot, pubspecFileName));
}

// If provided path is null, check if pubspec.yaml        --
// exists in the current directory                        --
// -----------------------------------------------------------------
// -- Get details about the current project                       --
Future<dynamic> _getPackageInfo({String pPath}) async {
  log.d('Argument Path: ${pPath}');
  try {
    (pPath != null)
        ? (pPath.contains(pubspecFileName))
            ? pubspecFile = await _pubspecInPath(pPath)
            : pubspecFile = await _pubspecNotInPath(pPath)
        : pubspecFile = File(p.join(Directory.current.path, pubspecFileName));

  } on Exception catch (e) {
    log.e('${e.toString()}: $pubSpecNotFound');
    return;
  }

  projectRoot = projectRoot.replaceAll(RegExp(r'\\'), '/');
  return Pubspec.parse(await pubspecFile.readAsString());
}

void main(List<String> arguments) async {
  exitCode = 0;

  // ---------------------------------------------------------------
  // -- Possible arguments to be accepted                         --
  final parser = ArgParser()
    ..addOption(
      fileLocation,
      defaultsTo: null,
      abbr: 'f',
      help: 'The path of the .dart file in which to convert imports to relative',
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
  log.d('Provided Path: ${usePath}');

  // ---------------------------------------------------------------
  // -- Determine if necessary arguments were provided, if not,   --
  // -- return error message                                      --
  if (usePath == null) {
    log.e('Either Directory Path (-d) or Pubspec Path (-p) required');
    return;
  }
  if (argResults[fileLocation] == null) {
    log.e('Filename (-f) in which to convert import paths is required');
    return;
  } else {
    try {
      filePath = await File(argResults[fileLocation]);
    } on Exception catch (e) {
      log.e('File Error: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------
  // -- Using provided arguments, determine project name          --
  // -- which will be used to locate package imports              --
  try {
    project = await _getPackageInfo(pPath: usePath);
  } on Exception catch (e) {
    log.e('${pubSpecNotFound} System Error Message: ${e.toString()}');
    return;
  }
  // ---------------------------------------------------------------
  // Regex pattern used to locate package imports                 --
  // https://github.com/luanpotter/vscode-dart-import/blob/fb7861b8e2d04e9d5f71e67fa21a1733463d3a96/src/main.ts#L50
  pattern = RegExp(
      '''^\\s*import\\s*(['"])package:${project.name}/([^'"]*)['"]([^;]*);\\s*\$''',
      multiLine: true
  );
  log.d('Project: ${project.name}');


  // ---------------------------------------------------------------
  // -- Get file path as Glob so as to help with cross platform   --
  // -- compatibility                                             --
  libPath = p.join(projectRoot, 'lib');
  log.d('Library Location: ${libPath}');
  final dartFile = Glob('**${filePath.nameWithoutExtension}.dart', caseSensitive: true, context: p.Context(style: (p.Style.platform.name == 'windows') ? p.Style.windows : p.Style.posix, current: libPath));

  // ---------------------------------------------------------------
  // -- Using CodeMod package to make and apply patches to code   --
  exitCode = runInteractiveCodemod(
    filePathsFromGlob(dartFile),
    RegexSubstituter(),
    // If -y flag was passed auto apply all changes               --
    args: [(argResults[autoApply]) ? '--yes-to-all' : ''],
  );
}

// -----------------------------------------------------------------
// -- Run file matching and code replacements                     --
class RegexSubstituter implements Suggestor {
  @override
  bool shouldSkip(String sourceFileContents) => false;

  @override
  Iterable<Patch> generatePatches(SourceFile sourceFile) sync* {
    final contents = sourceFile.getText(0);

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
