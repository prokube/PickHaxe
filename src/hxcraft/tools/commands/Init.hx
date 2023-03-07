package hxcraft.tools.commands;

import hxcraft.tools.commands.Help.CommandInfo;

/**
 * Command for initializing a new project.
*/
class Init implements ICommand
{
  public function new() {}

  /**
   * Retrieves information about a command, such as help text and usage.
   * @return The command information.
   */
  public function getCommandInfo():CommandInfo
  {
    return {
      blurb: 'Initialize a new project',
      description: 'Initializes a new HxCraft project in the current directory.',
      args: [],
      options: [
        {
          short: 'h',
          long: 'help',
          blurb: 'Output usage information',
          value: null,
        }
      ]
    };
  }

  /**
   * Perform the command.
   * @param args The arguments passed to the command.
   */
  public function perform(args:Array<String>):Void
  {
    CLI.print('Initializing new project...');

    var modId:String = CLI.prompt(
      {
        question: 'Enter your mod ID (e.g. my-test-mod): ',
        validator: validateModId
      });

    var modVersion:String = CLI.prompt(
      {
        question: 'Enter your mod version (default: 1.0.0): ',
        validator: validateVersion,
        defaultValue: '1.0.0'
      });

    var parentPackage:String = CLI.prompt(
      {
        question: 'Enter your parent package (e.g. com.example): ',
        validator: validateJavaPackage
      });

    var modEnvironment:String = CLI.prompt(
      {
        question: "Enter your mod's environment (default: Both):",
        options: [
          {label: 'Client', value: 'CLIENT'},
          {label: 'Server', value: 'SERVER'},
          {label: 'Both', value: '*'}
        ],
        defaultValue: '*'
      });

    var defaultModName:String = modId.kebabToTitle();

    var modName:String = CLI.prompt(
      {
        question: 'Enter your mod name (default: ' + defaultModName + '): ',
        defaultValue: defaultModName
      });

    var modDescription:String = CLI.prompt(
      {
        question: 'Enter your mod description: ',
        validator: input -> input.length > 0
      });

    var modParams:ModInitParameters =
      {
        modId: modId,
        modVersion: modVersion,
        parentPackage: parentPackage,
        modEnvironment: modEnvironment,
        modName: modName,
        modDescription: modDescription,

        entryClass: modId.kebabToTitle().replace(' ', '') + 'Mod'
      };

    CLI.print('Generating project...');
    buildXML(modParams);
    createSampleProject(modParams);
  }

  /**
   * Build a project.xml file from the given parameters.
   * @param modParams The parameters to use.
   */
  function buildXML(modParams:ModInitParameters):Void
  {
    var xmlData:String = IO.readFile(IO.libraryDir().joinPaths('templates/project.xml'));

    var xmlDataResult:String = applyModParams(xmlData, modParams);

    CLI.print('Writing project.xml...', Verbose);
    CLI.print(xmlDataResult, Verbose);

    IO.writeFile(IO.workingDir().joinPaths('project.xml'), xmlDataResult);
  }

  /**
   * Build a sample project from the given parameters.
   * @param modParams The parameters to use.
   */
  function createSampleProject(modParams:ModInitParameters):Void
  {
    // Make the class path.
    var classPath:String = modParams.parentPackage.split('.').join('/');

    var classTemplate:String = IO.readFile(IO.libraryDir().joinPaths('templates/ModEntryPoint.hx'));

    CLI.print('Writing to classpath...', Verbose);
    IO.makeDir(IO.workingDir().joinPaths('src', classPath));
    var classResult:String = applyModParams(classTemplate, modParams);
    CLI.print(classResult, Verbose);
    IO.writeFile(IO.workingDir().joinPaths('src', classPath, '${modParams.entryClass}.hx'), classResult);

    CLI.print('Writing to resourcepath...', Verbose);
    IO.makeDir(IO.workingDir().joinPaths('resources', classPath));
  }

  function applyModParams(input:String, modParams:ModInitParameters):String
  {
    return input.replace('#{hxcraft.mod.id}', modParams.modId)
      .replace('#{hxcraft.mod.version}', modParams.modVersion)
      .replace('#{hxcraft.mod.parentPackage}', modParams.parentPackage)
      .replace('#{hxcraft.mod.environment}', modParams.modEnvironment)
      .replace('#{hxcraft.mod.name}', modParams.modName)
      .replace('#{hxcraft.mod.description}', modParams.modDescription)
      .replace('#{hxcraft.mod.entryPoint}', modParams.entryClass);
  }

  /**
   * A mod ID must be at least 2 characters long,
   * and can only contain lowercase letters, numbers, and the symbols `-` and `_`.
   * @param input The mod ID to validate.
   * @return Whether the mod ID is valid.
   */
  function validateModId(input:String):Bool
  {
    if (input.length < 2) return false;

    return ~/^[a-z0-9_-]+$/.match(input);
  }

  /**
   * Validate a SemVer version.
   * 
   * @see https://semver.org/
   * @param input The version to validate.
   * @return Whether the version is valid.
   */
  function validateVersion(input:String):Bool
  {
    return
      ~/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/.match(input);
  }

  /**
   * Validate a Java package name.
   * 
   * @see https://stackoverflow.com/questions/29783092/regexp-to-match-java-package-name
   * @param input The package to validate.
   * @return Whether the package is valid.
   */
  function validateJavaPackage(input:String):Bool
  {
    if (input.length < 2) return false;

    return ~/^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*[a-z0-9_]*$/.match(input);
  }
}

/**
 * A structure containing data about the mod being initialized.
 */
typedef ModInitParameters =
{
  modId:String,
  modVersion:String,
  parentPackage:String,
  modEnvironment:String,
  modName:String,
  modDescription:String,
  entryClass:String
};
