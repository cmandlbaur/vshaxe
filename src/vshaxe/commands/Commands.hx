package vshaxe.commands;

import vshaxe.workspace.WorkspaceFolderModel;
import vshaxe.display.HaxeDisplayArgumentsProvider;
import vshaxe.server.LanguageServer;

class Commands {
    final context:ExtensionContext;
    final model:WorkspaceFolderModel;
    var server:LanguageServer;

    public function new(context:ExtensionContext, model:WorkspaceFolderModel) {
        this.model = model;
        this.context = context;

        context.registerHaxeCommand(RestartLanguageServer, () -> server.restart());
        context.registerHaxeCommand(RunGlobalDiagnostics, () -> server.runGlobalDiagnostics());
        context.registerHaxeCommand(ShowReferences, showReferences);
        context.registerHaxeCommand(ToggleCodeLens, toggleCodeLens);
        context.registerHaxeCommand(DebugSelectedConfiguration, debugSelectedConfiguration);

        #if debug
        context.registerHaxeCommand(ClearMementos, clearMementos);
        context.registerHaxeCommand(RunMethod, (method, params) -> server.runMethod(method, params));
        #end

        context.subscriptions.push(window.onDidChangeActiveTextEditor(updateWorkspaceFolder));
    }

    function updateWorkspaceFolder(editor:TextEditor) {
        if(editor == null) return;
        var workspaceFolderConfig = model.getConfigForFilePath(editor.document.uri);
        if(workspaceFolderConfig == null) return;

        server = workspaceFolderConfig.server;
    }

    function showReferences(uri:String, position:Position, locations:Array<Location>) {
        inline function copyPosition(position) return new Position(position.line, position.character);
        // this is retarded
        var locations = locations.map(function(location)
            return new Location(Uri.parse(cast location.uri), new Range(copyPosition(location.range.start), copyPosition(location.range.end)))
        );
        commands.executeCommand("editor.action.showReferences", Uri.parse(uri), copyPosition(position), locations).then(function(s) trace(s), function(s) trace("err: " + s));
    }

    function toggleCodeLens() {
        var key = "enableCodeLens";
        var config = workspace.getConfiguration("haxe");
        var info = config.inspect(key);
        var value = getCurrentConfigValue(info, config);
        // editing the global config only has an effect if there's no workspace value
        var global = info.workspaceValue == null;
        config.update(key, !value, global);
    }

    function debugSelectedConfiguration() {
        var haxeDisplayArgumentsProvider = model.getConfigForFilePath(window.activeTextEditor.document.uri).haxeDisplayArgumentsProvider;
        if (!haxeDisplayArgumentsProvider.isActive) {
            window.showErrorMessage("The built-in completion provider is not active, so there is no configuration to be debugged.");
            return;
        }

        var label = haxeDisplayArgumentsProvider.getCurrentLabel();
        if (label == null) {
            window.showErrorMessage("There is no configuration selected.");
            return;
        }
        function error() {
            window.showErrorMessage('There is no launch configuration named \'$label\'.');
        }

        // work around https://github.com/Microsoft/vscode/issues/53874 by checking the launch.json contents :/
        var folder = workspace.workspaceFolders[0];
        var launchConfigs = workspace.getConfiguration("launch", folder.uri);
        var configurations:Array<{name:String}> = launchConfigs.get("configurations");
        var compounds:Array<{name:String}> = launchConfigs.get("compounds");

        var allConfigs = [];
        if (configurations != null) {
            allConfigs = allConfigs.concat(configurations);
        }
        if (compounds != null) {
            allConfigs = allConfigs.concat(compounds);
        }

        if (allConfigs.exists(config -> config.name == label)) {
            debug.startDebugging(folder, label);
        } else {
            error();
        }
    }

    function clearMementos() {
        inline function clear(key) context.workspaceState.update(key, js.Lib.undefined);
        clear(vshaxe.display.DisplayArguments.ProviderNameKey);
        clear(vshaxe.display.HaxeDisplayArgumentsProvider.ConfigurationIndexKey);
        clear(vshaxe.HxmlDiscovery.DiscoveredFilesKey);
    }

    function getCurrentConfigValue<T>(info, config:WorkspaceConfiguration):T {
        var value = info.workspaceValue;
        if (value == null)
            value = info.globalValue;
        if (value == null)
            value = info.defaultValue;
        return value;
    }
}

private typedef LaunchJson = {
    var ?compounds:Array<{name:String}>;
    var ?configurations:Array<{name:String}>;
}
