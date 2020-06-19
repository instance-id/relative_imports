# relative_imports

An IDE agnostic tool to automatically convert your projects dart/flutter imports to relative imports.  

Example:   
Your import may go from something like this:
```dart
import 'package:dart_relative_imports/file1.dart';
import 'package:dart_relative_imports/folder1/file2.dart';
import 'package:dart_relative_imports/folder2/file3.dart';
 ```
to something like this:
```dart
import 'file1.dart';
import 'folder1/file2.dart';
import '../folder2/file3.dart';
 ```

Example configuration for IntelliJ or Android Studio:

![](.repo_images/szZSQzf.png)

Example usage via command line:
```
C:\tools\relative_imports.exe -p C:\projects\my_project\pubspec.yaml -f 
```

Arguments:  
```
 file-name        (-f)  The name of the .dart file in which to convert imports to relative
 directory-path   (-d) 1) Project root directory (1 or 2 Required)
 pubspec-location (-p) 2) The path to your projects pubspec.yaml (1 or 2 Required)
 auto-apply       (-y) If -y argument is set, automatically apply all import changes. Otherwise you will be prompted to confirm the changes        
 verbose          (-v) If -v argument is set, additional log messages will be shown
```