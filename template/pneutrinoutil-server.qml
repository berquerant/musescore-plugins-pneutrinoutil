import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.5
import QtQuick.Layouts 1.0
import FileIO 3.0
import QtQuick.Dialogs 1.2

MuseScore {
  menuPath: "Plugins.pneutrinoutil-server"
  description: "Generate wav file by pneutrinoutil"
  version: "1.0.0"
  requiresScore: true
  pluginType: "dock"
  dockArea: "left"
  id: uiPneutrinoutilServer
  width: 350

  //
  // event handlers
  //

  onRun: { }

  function onRunClicked() {
    setParameters();
    windowResultNewProc.update();
  }

  function onInfoClicked() {
    setParameters();
    windowProcList.update();
  }

  function onConfigClicked(index) {
    windowResultBody.updateByGetConfig(getRequestIDFromProcList(index));
  }

  function onLogClicked(index) {
    windowResultBody.updateByGetLog(getRequestIDFromProcList(index));
  }

  function onXMLClicked(index) {
    windowResultBody.updateByGetMusicXML(getRequestIDFromProcList(index));
  }

  function onWavClicked(index) {
    dialogDownloadWav.update(getRequestIDFromProcList(index));
  }

  //
  // constants
  //

  readonly property string requestIDHeader : "x-request-id"

  //
  // utilities
  //

  // Get request id from response header.
  //
  // xhr; XMLHttpRequest
  // returns: string
  function getRequestID(xhr) {
    return xhr.getResponseHeader(requestIDHeader);
  }

  // Return the URL of the API.
  //
  // path: string
  // returns: string
  function newURL(path) {
    return endpoint + path;
  }

  //
  // Temporary musicxml file
  //

  FileIO {
    id: tempMusicXMLFile
    source: tempPath() + curScore.scoreName + ".musicxml"
  }

  // Read musicxml file as string.
  //
  // returns: string
  function readTempMusicXML() {
    return tempMusicXMLFile.read();
  }
  // Write current score as musicxml.
  function writeTempMusicXML() {
    writeScore(curScore, tempMusicXMLFile.source, "musicxml");
  }
  function curScoreAsMusicXMLFilename() {
    return curScore.scoreName + ".musicxml";
  }
  function curScoreAsMusicXMLString() {
    writeTempMusicXML();
    return readTempMusicXML();
  }

  // Send HTTP GET request to the API.
  // Display windowError if the response status is not 200 or callback fails.
  //
  // path: string
  // callback: function(XMLHTTPRequest)
  function getFromServer(path, callback) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) {
        return;
      }
      const status = xhr.status;
      const rid = getRequestID(xhr);
      if (status != 200) {
        windowError.display(rid, "Request failed", path, status, xhr.responseText);
        return;
      }
      try {
        callback(xhr);
      } catch (err) {
        windowError.display(rid, err.toString(), path, status, xhr.responseText);
      }
    };
    xhr.open("GET", newURL(path));
    xhr.send();
  }

  //
  // State
  //

  // list of {rid: string, basename: string, created_at: string}
  property var procList : []

  function getRequestIDFromProcList(index) {
    curRequestID = procList[index].rid;
    return curRequestID;
  }
  property var curRequestID : ""

  //
  // Parameters from UI elements
  //

  // Set the values of main UI to the properties.
  function setParameters() {
    endpoint = textEndpoint.text;
    model = textModel.text;
    inference = textInference.text;
    formantShift = textFormantShift.text;
    styleShift = textStyleShift.text;
    enhanceBreathiness = textEnhanceBreathiness.text;
    pitchShiftNsf = textPitchShiftNsf.text;
    pitchShiftWorld = textPitchShiftWorld.text;
    smoothFormant = textSmoothFormant.text;
    smoothPitch = textSmoothPitch.text;
  }

  property var endpoint : "${PNEUTRINOUTIL_SERVER_ENDPOINT}"
  property var model : ""
  property var inference: ""
  property var formantShift: ""
  property var styleShift: ""
  property var enhanceBreathiness: ""
  property var pitchShiftNsf: ""
  property var pitchShiftWorld: ""
  property var smoothFormant: ""
  property var smoothPitch: ""

  //
  // UI elements
  //

  QProcess {
    id: processDownloadWav
  }

  // Dialog to choose the directory to install.
  FileDialog {
    id: dialogDownloadWav
    title: "Choose a folder to install the wav file"
    folder: shortcuts.home
    selectFolder: true
    selectMultiple: false
    onAccepted: {
      download(curRequestID, dialogDownloadWav.fileUrl);
    }

    // Download wav by curl.
    //
    // rid: string
    // destFolderURL: string
    //
    // TODO: write binary data to local file by QML
    function download(rid, destFolderURL) {
      const path = newURL("/proc/" + rid + "/wav");
      const dest = (destFolderURL + "/" + rid + ".wav").replace("file://", "");
      const cmd = [
        "${CURL}",
        "-o",
        dest,
        path
      ].join(" ");
      processDownloadWav.start(cmd);
    }

    // Download wav file.
    function update() {
      dialogDownloadWav.open();
    }
  }

  // Window to display the result of craeting a new process.
  ApplicationWindow {
    id: windowResultNewProc
    visible: false
    title: "New process created!"
    GridLayout {
      anchors.fill: parent
      columns: 2
      rowSpacing: 0
      columnSpacing: 5
      Label {
        text: "<b>RequestID</b>"
      }
      TextField {
        id: textResultNewProcRequestID
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        text: "<b>Status</b>"
      }
      TextField {
        id: textResultNewProcStatus
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        text: "<b>Body</b>"
      }
      TextArea {
        id: textResultNewProcBody
        readOnly: true
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: ""
      }
    }

    function update() {
      const path = newURL("/proc");
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
          return;
        }
        const status = xhr.status;
        const rid = getRequestID(xhr);
        if (status != 202) {
          windowError.display(rid, "Request failed", path, status, xhr.responseText);
          return;
        }
        try {
          const body = JSON.parse(xhr.responseText);
          textResultNewProcRequestID.text = rid;
          textResultNewProcStatus.text = status.toString();
          textResultNewProcBody.text = body.data;
          windowResultNewProc.visible = true;
        } catch (err) {
          windowError.display(rid, err.toString(), path, status, xhr.responseText);
        }
      };
      xhr.open("POST", path);
      const boundary = newFormDataBoundary();
      xhr.setRequestHeader("Content-Type", "multipart/form-data; boundary=" + boundary);
      xhr.send(buildFormData(boundary));
    }

    // Build the form data body.
    //
    // returns: string
    function buildFormData(boundary) {
      var body = "";
      body += newFormDataFile(boundary, "score", curScoreAsMusicXMLFilename(), curScoreAsMusicXMLString());
      const fdMap = newFormDataFieldMap();
      for (var key in fdMap) {
        body += newFormDataField(boundary, key, fdMap[key]);
      }
      body += newFormDataEnd(boundary);
      return body;
    }

    // Return a map: form data name to values.
    //
    // returns: map<string, string>
    function newFormDataFieldMap() {
      return {
        "enhanceBreathiness": enhanceBreathiness,
        "formantShift": formantShift,
        "inference": inference,
        "model": model,
        "pitchShiftNsf": pitchShiftNsf,
        "pitchShiftWorld": pitchShiftWorld,
        "smoothFormant": smoothFormant,
        "smoothPitch": smoothPitch,
        "styleShift": styleShift
      };
    }

    // Return the end of the form data.
    //
    // boundary: string
    // returns: string
    function newFormDataEnd(boundary) {
      return "--" + boundary + "--\r\n";
    }

    // Return a new form data file like FormData.append().
    //
    // boundary: string
    // name: string
    // filename: string
    // data: string
    // returns: string
    function newFormDataFile(boundary, name, filename, data) {
      var body = "--" + boundary + "\r\n";
      body += 'Content-Disposition: form-data; name="' + name + '"; filename="' + filename + '"\r\n';
      body += 'Content-Type: application/octet-stream\r\n\r\n';
      body += data + "\r\n";
      return body;
    }

    // Return a new form data field like FormData.append().
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/MIME_types#multipartform-data
    //
    // boundary: string
    // name: string
    // data: string
    // returns: string
    function newFormDataField(boundary, name, data) {
      var body = "--" + boundary + "\r\n";
      body += 'Content-Disposition: form-data; name="' + name + '"\r\n\r\n';
      body += data + "\r\n";
      return body;
    }

    // Return a new multipart form data boundary.
    //
    // returns: string
    function newFormDataBoundary() {
      return '------------' + Math.random().toString(36).substring(7);
    }
  } // windowResultNewProc

  // Window to display the response body of the GET request.
  ApplicationWindow {
    id: windowResultBody
    visible: false
    title: "Result"
    width: 600
    height: 300
    GridLayout {
      anchors.fill: parent
      columns: 1
      rowSpacing: 0
      columnSpacing: 5
      TextArea {
        id: textResultBody
        readOnly: true
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: ""
      }
    }

    // Set info from /proc/:id/config and display this.
    //
    // rid: string
    function updateByGetConfig(rid) {
      getFromServer("/proc/" + rid + "/config", function (xhr) {
        const data = JSON.parse(xhr.responseText);
        textResultBody.text = JSON.stringify(data.data, null, "  ");
        windowResultBody.visible = true;
      });
    }
    // Set info from /proc/:id/log and display this.
    //
    // rid: string
    function updateByGetLog(rid) {
      getFromServer("/proc/" + rid + "/log", function (xhr) {
        textResultBody.text = xhr.responseText;
        windowResultBody.visible = true;
      });
    }
    // Set info from /proc/:id/musicxml and display this.
    //
    // rid: string
    function updateByGetMusicXML(rid) {
      getFromServer("/proc/" + rid + "/musicxml", function (xhr) {
        textResultBody.text = xhr.responseText;
        windowResultBody.visible = true;
      });
    }
  } // windowResultBody

  // Window to display the list of results, get detailed result.
  ApplicationWindow {
    id: windowProcList
    visible: false
    title: "ProcList"
    width: 350
    height: 300
    Component {
      id: procListDelegate

      Item {
        width: 350
        height: 100
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: {
            // move focus to entered row
            procListView.currentIndex = index;
          }
          ColumnLayout {
            anchors.margins: 0
            spacing: 10
            GridLayout {
              columns: 2
              rowSpacing: 0
              columnSpacing: 5
              Label {
                text: "<b>ID</b>"
              }
              Text {
                text: rid
              }
              Label {
                text: "<b>Basename</b>"
              }
              Text {
                text: basename
              }
              Label {
                text: "<b>CreatedAt</b>"
              }
              Text {
                text: createdAt
              }
            }
            //
            // Buttons to get detailes
            //
            GridLayout {
              columns: 4
              rowSpacing: 0
              Button {
                text: "Config"
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // move focus to the row
                    procListView.currentIndex = index;
                    onConfigClicked(index);
                  }
                }
              }
              Button {
                text: "Log"
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // move focus to the row
                    procListView.currentIndex = index;
                    onLogClicked(index);
                  }
                }
              }
              Button {
                text: "XML"
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // move focus to the row
                    procListView.currentIndex = index;
                    onXMLClicked(index);
                  }
                }
              }
              Button {
                text: "Wav"
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // move focus to the row
                    procListView.currentIndex = index;
                    onWavClicked(index);
                  }
                }
              }
            }
          }
        }
      }
    }
    ListModel {
      id: modelProcList
    }
    ListView {
      id: procListView
      anchors.fill: parent
      model: modelProcList
      delegate: procListDelegate
      highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
      focus: true
      highlightFollowsCurrentItem: true
    }

    // Set info from /proc and display this.
    function update() {
      getFromServer("/proc", function (xhr) {
        const data = JSON.parse(xhr.responseText);
        procList = data.data;
        // descending order of created_at
        procList.sort(function(a, b) {
          const left = a.created_at;
          const right = b.created_at;
          if (left < right) {
            return 1;
          }
          if (left > right) {
            return -1;
          }
          return 0;
        });
        modelProcList.clear();
        for (var i = 0; i < procList.length; i++) {
          const item = procList[i];
          modelProcList.append({
            "rid": item.rid,
            "basename": item.basename,
            "createdAt": item.created_at
          });
        }
        windowProcList.visible = true;
      });
    }
  } // windowProcList

  // Window to display errors.
  ApplicationWindow {
    id: windowError
    visible: false
    title: "Error!"
    width: 600
    GridLayout {
      anchors.fill: parent
      columns: 2
      rowSpacing: 0
      columnSpacing: 5
      Label {
        id: labelErrorMessage
        text: "Message"
        color: "White"
      }
      TextField {
        id: textErrorMessage
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        id: labelErrorRequestID
        text: "RequestID"
        color: "White"
      }
      TextField {
        id: textErrorRequestID
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        id: labelErrorPath
        text: "Path"
        color: "White"
      }
      TextField {
        id: textErrorPath
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        id: labelErrorStatus
        text: "Status"
        color: "White"
      }
      TextField {
        id: textErrorStatus
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
      Label {
        id: labelErrorBody
        text: "Body"
        color: "White"
      }
      TextArea {
        id: textErrorBody
        readOnly: true
        Layout.fillWidth: true
        text: ""
      }
    }

    // Set info and display this.
    //
    // rid: string
    // message: string
    // path: string
    // status: int
    // body: string
    function display(rid, message, path, status, body) {
      textErrorRequestID.text = rid;
      textErrorMessage.text = message;
      textErrorPath.text = path;
      textErrorStatus.text = status.toString();
      textErrorBody.text = body;
      windowError.visible = true;
    }
  } // windowError

  // Main UI
  ColumnLayout {
    id: mainRow
    spacing: 2
    anchors.margins: 0
    anchors.fill: parent
    Layout.fillWidth: true

    GridLayout {
      anchors.fill: parent
      columns: 2
      rowSpacing: 5
      columnSpacing: 5
      Layout.fillWidth: true

      // Run button
      Button {
        id: buttonRun
        text: "Run"
        onClicked: {
          onRunClicked()
        }
      }
      // Info button
      Button {
        id: buttonInfo
        text: "Info"
        onClicked: {
          onInfoClicked()
        }
      }
      // Endpoint input
      Label {
        id: labelEndpoint
        text: "Endpoint"
        color: "White"
      }
      TextField {
        id: textEndpoint
        text: "${PNEUTRINOUTIL_SERVER_ENDPOINT}"
        Layout.fillWidth: true
      }
      // Model input
      Label {
        id: labelModel
        text: "Model"
        color: "White"
      }
      TextField {
        id: textModel
        text: "KIRITAN"
        Layout.fillWidth: true
      }
      // Inference input
      Label {
        id: labelInference
        text: "Inference (2,3,4)"
        color: "White"
      }
      TextField {
        id: textInference
        text: "3"
        validator: IntValidator {bottom: 2; top: 4;}
        Layout.fillWidth: true
      }
      // FormantShift input
      Label {
        id: labelFormantShift
        text: "FormantShift"
        color: "White"
      }
      TextField {
        id: textFormantShift
        text: "1.0"
        Layout.fillWidth: true
      }
      // StyleShift input
      Label {
        id: labelStyleShift
        text: "StyleShift"
        color: "White"
      }
      TextField {
        id: textStyleShift
        text: "0"
        Layout.fillWidth: true
      }
      // EnhanceBreathiness input
      Label {
        id: labelEnhanceBreathiness
        text: "EnhanceBreathiness [0, 100]%"
        color: "White"
      }
      TextField {
        id: textEnhanceBreathiness
        text: "0"
        validator: DoubleValidator {bottom: 0; top: 100;}
        Layout.fillWidth: true
      }
      // PitchShiftNsf input
      Label {
        id: labelPitchShiftNsf
        text: "PitchShiftNsf"
        color: "White"
      }
      TextField {
        id: textPitchShiftNsf
        text: "0.0"
        Layout.fillWidth: true
      }
      // PitchShiftWorld input
      Label {
        id: labelPitchShiftWorld
        text: "PitchShiftWorld"
        color: "White"
      }
      TextField {
        id: textPitchShiftWorld
        text: "0.0"
        Layout.fillWidth: true
      }
      // SmoothFormant input
      Label {
        id: labelSmoothFormant
        text: "SmoothFormant [0, 100]%"
        color: "White"
      }
      TextField {
        id: textSmoothFormant
        text: "0.0"
        validator: DoubleValidator {bottom: 0; top: 100;}
        Layout.fillWidth: true
      }
      // SmoothPitch input
      Label {
        id: labelSmoothPitch
        text: "SmoothPitch [0, 100]%"
        color: "White"
      }
      TextField {
        id: textSmoothPitch
        text: "0.0"
        validator: DoubleValidator {bottom: 0; top: 100;}
        Layout.fillWidth: true
      }
    }
  } // mainRow
}
