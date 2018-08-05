package vshaxe.workspace;

import vshaxe.helper.HaxeExecutable;
import vshaxe.display.DisplayArguments;
import vshaxe.server.LanguageServer;
import vshaxe.display.HaxeDisplayArgumentsProvider;

typedef WorkspaceFolderConfig = {
    var haxeExecutable:HaxeExecutable;
    var displayArguments:DisplayArguments;
    var server:LanguageServer;
    var haxeDisplayArgumentsProvider:HaxeDisplayArgumentsProvider;
}