class DelegateModal {

    static delegate(azInfo){
		let url = 'https://vimsorchestrator.azurewebsites.net/api/azuredevops';
		$.post( url, { azproject: azInfo.azProject, azarea: azInfo.azArea, aztoken: azInfo.azToken, vimsid: azInfo.vimsId } );
    }
}

DelegateModal.html = `
<div id="vims">
	<div id="delegateModal" class="vims-modal">
		<p>Azure project: <input type="text" id="vims-az-project"/></p>
		<p>Azure project area: <input type="text" id="vims-az-project-area"/></p>
		<p>Azure access token: <input type="text" id="vims-az-token"/></p>
		<p>Save settings &nbsp;<input type="checkbox" id="vims-save-settings"/></p>
		<p>
			<a href="#" rel="modal:close">Close</a>
			&nbsp;
			<input type="button" value="Ok" onclick="SendDelegation()"/>
		</p>
	</div>
</div>
`;

DelegateModal.css = '<link id="cssModal" rel="stylesheet" href="/assets/vims/vims_modal.css" />';

function SendDelegation(){
	let azInfo = new AzDevOpsConnectionInfo();
	azInfo.azToken = $("#vims-az-token").val();
	azInfo.azProject = $("#vims-az-project").val();
	azInfo.azArea = $("#vims-az-project-area").val();
	azInfo.vimsId = document.URL.substr(document.URL.lastIndexOf('/') + 1);

	DelegateModal.delegate(azInfo);
}

class AzDevOpsConnectionInfo {
	azToken = '';
	azProject = '';
	azArea = '';
	vimsId = 0;
}
