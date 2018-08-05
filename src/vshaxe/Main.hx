package vshaxe;

import vshaxe.commands.Commands;
import vshaxe.commands.InitProject;
import vshaxe.view.dependencies.DependencyTreeView;
import vshaxe.view.methods.MethodTreeView;
import vshaxe.display.DisplayArguments;
import vshaxe.display.DisplayArgumentsSelector;
import vshaxe.display.HaxeDisplayArgumentsProvider;
import vshaxe.helper.HxmlParser;
import vshaxe.helper.HaxeCodeLensProvider;
import vshaxe.helper.HaxeExecutable;
import vshaxe.server.LanguageServer;
import vshaxe.tasks.HaxeTaskProvider;
import vshaxe.tasks.HxmlTaskProvider;
import vshaxe.tasks.TaskConfiguration;
import vshaxe.workspace.WorkspaceFolderModel;
import vshaxe.workspace.WorkspaceRootBuilder;

class Main {
    var api:Vshaxe;

    function new(context:ExtensionContext) {
        new InitProject(context);
        commands.executeCommand("setContext", "vshaxeActivated", true); // https://github.com/Microsoft/vscode/issues/10471

        var workspaceFolderModel = new WorkspaceFolderModel();
        var builder = new WorkspaceRootBuilder(context, workspaceFolderModel);
        for (workspaceFolder in workspaceFolderModel.workspaceFolders) {
            api = builder.build(workspaceFolder);
        }

        for(config in workspaceFolderModel.workspaceFolderConfigs) {
			config.displayArguments.selectProvider("Haxe");
			config.haxeDisplayArgumentsProvider.updateWorkspaceFolderConfig(config);
			config.server.start();
		}
    }

    @:keep
    @:expose("activate")
    static function main(context:ExtensionContext) {
        return new Main(context).api;
    }
}
