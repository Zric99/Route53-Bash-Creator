# Electron UI für Route53 Bash Creator

Dieses UI zeigt eine moderne Eingabemaske mit Preview-Box für alle Werte, die vor dem Anlegen des Records angezeigt werden. Die Komponenten sind in React geschrieben und können in eine Electron-App eingebunden werden.

## Komponenten
- `FormWithPreview.jsx`: Hauptformular mit Preview und "Create Record"-Button
- `RecordPreview.jsx`: Zeigt die Vorschau der eingegebenen Werte

## Integration
1. Electron-Projekt initialisieren (z.B. mit `npx create-electron-app` oder manuell)
2. React-Komponenten einbinden (z.B. mit Vite oder Create React App im Renderer)
3. Die Bash-Logik kann per Node.js-ChildProcess aus dem Renderer/Backend ausgeführt werden.

## Vorschau
Die Vorschau zeigt alle relevanten Felder, bevor der Record angelegt wird. So siehst du vorab, was tatsächlich erstellt wird.
