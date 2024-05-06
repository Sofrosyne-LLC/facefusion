!include nsDialogs.nsh
!include LogicLib.nsh
!include MUI2.nsh

Name 'FaceFusion NEXT'
OutFile 'FaceFusion_NEXT.exe'

RequestExecutionLevel admin

!define MUI_ICON 'facefusion.ico'
!insertmacro MUI_PAGE_DIRECTORY

Page custom InstallPage PostInstallPage
Page InstFiles

UninstPage uninstConfirm
UninstPage InstFiles

Var UseDefault
Var UseCuda
Var UseDirectMl
Var UseOpenVino

Function .onInit
	StrCpy $INSTDIR 'C:\FaceFusion'
FunctionEnd

Function InstallPage
	nsDialogs::Create 1018

	${NSD_CreateRadioButton} 0 40u 100% 10u 'Default'
	Pop $UseDefault

	${NSD_CreateRadioButton} 0 55u 100% 10u 'CUDA (NVIDIA)'
	Pop $UseCuda

	${NSD_CreateRadioButton} 0 70u 100% 10u 'DirectML (AMD, Intel, NVIDIA)'
	Pop $UseDirectMl

	${NSD_CreateRadioButton} 0 85u 100% 10u 'OpenVINO (Intel)'
	Pop $UseOpenVino

	${NSD_Check} $UseDefault

	nsDialogs::Show
FunctionEnd

Function PostInstallPage
	${NSD_GetState} $UseDefault $UseDefault
	${NSD_GetState} $UseCuda $UseCuda
	${NSD_GetState} $UseDirectMl $UseDirectMl
	${NSD_GetState} $UseOpenVino $UseOpenVino
FunctionEnd

Section 'Prepare Your Platform'
	DetailPrint 'Install WinGet'
	ExecWait 'powershell -WindowStyle Hidden -Command Start-BitsTransfer -Source https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -Destination Microsoft.VCLibs.appx'
	ExecWait 'powershell -WindowStyle Hidden -Command Start-BitsTransfer -Source https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -Destination Microsoft.UI.Xaml.appx'
	ExecWait 'powershell -WindowStyle Hidden -Command Start-BitsTransfer -Source https://aka.ms/getwinget -Destination WinGet.msixbundle'
	ExecWait 'powershell -WindowStyle Hidden -Command Add-AppxPackage Microsoft.VCLibs.appx'
	ExecWait 'powershell -WindowStyle Hidden -Command Add-AppxPackage Microsoft.UI.Xaml.appx'
	ExecWait 'powershell -WindowStyle Hidden -Command Add-AppxPackage WinGet.msixbundle'

	DetailPrint 'Install GIT'
	nsExec::Exec 'winget install -e --id Git.Git --silent --accept-source-agreements --force'

	DetailPrint 'Install Conda'
	nsExec::Exec 'winget install -e --id Anaconda.Miniconda3 --override "/InstallationType=JustMe /AddToPath=1 /S" --accept-source-agreements --force'

	DetailPrint 'Install FFmpeg'
	nsExec::Exec 'winget install -e --id Gyan.FFmpeg --accept-source-agreements --force'

	DetailPrint 'Install Codec'
	nsExec::Exec 'winget install -e --id CodecGuide.K-LiteCodecPack.Basic --silent --accept-source-agreements --force'
SectionEnd

Section 'Download Your Copy'
	SetOutPath $INSTDIR

	DetailPrint 'Download Your Copy'
	RMDir /r $INSTDIR
	nsExec::Exec '$PROGRAMFILES64\Git\cmd\git.exe clone https://github.com/facefusion/facefusion --branch next .'
SectionEnd

Section 'Setup Your Environment'
	DetailPrint 'Setup Your Environment'
	nsExec::Exec '$PROFILE\miniconda3\Scripts\conda.exe init --all'
	nsExec::Exec '$PROFILE\miniconda3\Scripts\conda.exe create --name facefusion python=3.10 --yes'
SectionEnd

Section 'Create Install Batch'
	SetOutPath $INSTDIR

	FileOpen $0 install-accelerator.bat w
	FileOpen $1 install-application.bat w
	${If} $UseDefault == 1
		FileWrite $1 '@echo off && conda activate facefusion && python install.py --onnxruntime default'
	${EndIf}
	${If} $UseCuda == 1
		FileWrite $0 '@echo off && conda activate facefusion && conda install cudatoolkit=11.8 cudnn=8.9.2.26 conda-forge::gputil=1.4.0 conda-forge::zlib-wapi'
		FileWrite $1 '@echo off && conda activate facefusion && python install.py --onnxruntime cuda-11.8'
	${EndIf}
	${If} $UseDirectMl == 1
		FileWrite $1 '@echo off && conda activate facefusion && python install.py --onnxruntime directml'
	${EndIf}
	${If} $UseOpenVino == 1
		FileWrite $0 '@echo off && conda activate facefusion && conda install conda-forge::openvino=2024.1.0'
		FileWrite $1 '@echo off && conda activate facefusion && python install.py --onnxruntime openvino'
	${EndIf}
	FileClose $0
	FileClose $1
SectionEnd

Section 'Install Your Accelerator'
	SetOutPath $INSTDIR

	DetailPrint 'Install Your Accelerator'
	nsExec::Exec 'install-accelerator.bat'
SectionEnd

Section 'Install The Application'
	SetOutPath $INSTDIR

	DetailPrint 'Install The Application'
	nsExec::ExecToLog 'install-application.bat'
SectionEnd

Section 'Create Run Batch'
	SetOutPath $INSTDIR
	FileOpen $0 run.bat w
	FileWrite $0 '@echo off && conda activate facefusion && python run.py --open-browser'
	FileClose $0
SectionEnd

Section 'Register The Application'
	DetailPrint 'Register The Application'
	CreateDirectory $SMPROGRAMS\FaceFusion
	CreateShortcut $SMPROGRAMS\FaceFusion\FaceFusion.lnk $INSTDIR\run.bat '' $INSTDIR\.install\facefusion.ico
	WriteUninstaller $INSTDIR\Uninstall.exe

	WriteRegStr HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion DisplayName 'FaceFusion'
	WriteRegStr HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion DisplayVersion 'NEXT'
	WriteRegStr HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion Publisher 'Henry Ruhs'
	WriteRegStr HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion InstallLocation $INSTDIR
	WriteRegStr HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion UninstallString $INSTDIR\uninstall.exe
SectionEnd

Section 'Uninstall'
	RMDir /r $SMPROGRAMS\FaceFusion
	RMDir /r $INSTDIR

	DeleteRegKey HKLM SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FaceFusion
SectionEnd

!insertmacro MUI_LANGUAGE English
