package vshaxe.workspace;

import vshaxe.tasks.HaxeTaskProvider;
import vshaxe.tasks.HxmlTaskProvider;
import vshaxe.tasks.TaskConfiguration;
import vshaxe.display.HaxeDisplayArgumentsProvider;
import vshaxe.server.LanguageServer;
import vshaxe.helper.HxmlParser;
import vshaxe.display.DisplayArguments;
import vshaxe.commands.Commands;
import vshaxe.view.methods.MethodTreeView;
import vshaxe.helper.HaxeCodeLensProvider;
import vshaxe.display.DisplayArgumentsSelector;
import vshaxe.view.dependencies.DependencyTreeView;
import vshaxe.helper.HaxeExecutable;

class WorkspaceRootBuilder {
    final problemMatchers = ["$haxe-absolute", "$haxe", "$haxe-error", "$haxe-trace"];
	final context:ExtensionContext;
	final workspaceMementos:WorkspaceMementos;
	final workspaceFolderModel:WorkspaceFolderModel;

    public function new(context:ExtensionContext, workspaceFolderModel:WorkspaceFolderModel) {
		this.context = context;
		this.workspaceFolderModel = workspaceFolderModel;
		workspaceMementos = new WorkspaceMementos(context.workspaceState);
		new DependencyTreeView(context, workspaceFolderModel);
		new HaxeCodeLensProvider();
		new MethodTreeView(context, workspaceFolderModel);
		new DisplayArgumentsSelector(context, workspaceFolderModel);
		new Commands(context, workspaceFolderModel);
    }

    public function build(workspaceFolder:WorkspaceFolder):Vshaxe {
		var displayArguments = new DisplayArguments(workspaceFolder, workspaceMementos);
		context.subscriptions.push(displayArguments);

        var haxeExecutable = new HaxeExecutable(workspaceFolder);
		context.subscriptions.push(haxeExecutable);

		var api = {
			haxeExecutable: haxeExecutable,
			enableCompilationServer: true,
			problemMatchers: problemMatchers.copy(),
			taskPresentation: {},
			registerDisplayArgumentsProvider: displayArguments.registerProvider,
			parseHxmlToArguments: HxmlParser.parseToArgs
		};

		var server = new LanguageServer(workspaceFolder, context, haxeExecutable, displayArguments, api);
		context.subscriptions.push(server);

		var hxmlDiscovery = new HxmlDiscovery(workspaceFolder, workspaceMementos);
		context.subscriptions.push(hxmlDiscovery);

		var haxeDisplayArgumentsProvider = new HaxeDisplayArgumentsProvider(context, workspaceFolderModel, workspaceFolder);
		haxeDisplayArgumentsProvider.observeHXMLFiles(hxmlDiscovery);

		var taskConfiguration = new TaskConfiguration(haxeExecutable, problemMatchers, server, api);
		new HxmlTaskProvider(taskConfiguration, hxmlDiscovery);
		new HaxeTaskProvider(taskConfiguration, displayArguments, haxeDisplayArgumentsProvider);

		// if (displayArguments.arguments == null) {
		// 	server.start();
		// }

		workspaceFolderModel.storeConfig(workspaceFolder.uri, {
			haxeExecutable: haxeExecutable,
			displayArguments: displayArguments,
			server: server,
			haxeDisplayArgumentsProvider: haxeDisplayArgumentsProvider
		});

		return api;
	}
}