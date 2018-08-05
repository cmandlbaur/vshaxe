package vshaxe.workspace;

import haxe.ds.StringMap;

class WorkspaceFolderModel {
    public var workspaceRoot(get, never):WorkspaceFolder;
    public var workspaceFolders(get, never):Iterator<WorkspaceFolder>;
    public var workspaceFolderConfigs(get, never):Iterator<WorkspaceFolderConfig>;
    var configMap:StringMap<WorkspaceFolderConfig>;

    public function new() {
        configMap = new StringMap<WorkspaceFolderConfig>();
    }

    function get_workspaceRoot():WorkspaceFolder {
        return (workspace.workspaceFolders == null) ? null : workspace.workspaceFolders[0];
    }

    function get_workspaceFolders():Iterator<WorkspaceFolder> {
        return [workspaceRoot].iterator();
    }

    function get_workspaceFolderConfigs():Iterator<WorkspaceFolderConfig> {
		return configMap.iterator();
	}

    public function storeConfig(folderPath:Uri, config:WorkspaceFolderConfig) {
        configMap.set(folderPath.toString(), config);
    }

    public function getConfig(folderPath:Uri):WorkspaceFolderConfig {
        return configMap.get(folderPath.toString());
    }

	public function getWorkspaceFolderForFile(filePath:Uri):WorkspaceFolder {
		return workspace.getWorkspaceFolder(filePath);
	}

	public function getConfigForFilePath(filePath:Uri):WorkspaceFolderConfig {
		var workspaceFolder = getWorkspaceFolderForFile(filePath);
		if(workspaceFolder == null) return null;

        var workspaceFolderPath = workspaceFolder.uri;

		return getConfig(workspaceFolderPath);
    }
}