Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

Function Update-EphingTemplate {
    Param ( 
        $LogFileList,
        $TemplateText
    )
    $Scriptblock = {
        $LogFileList = $args[0]
        $TemplateText = $args[1]
        $WindowHashTable.RunspaceRunning = $true
        $WindowHashTable.WindowDataContext.ProgressText = 'Please wait...'
        try {
            
            $WindowHashTable.WindowDataContext.LogDataGrid = (Get-Content $LogFileList) | ConvertFrom-String -TemplateContent $TemplateText
            $WindowHashTable.RunSpaceRunning = $false
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            $Popup = New-Object -ComObject wscript.shell
            $Popup.Popup("Error!`n$ErrorMessage",0,"Error!",16)

        }
        $WindowHashTable.WindowDataContext.ProgressText = 'Done!'
    }
    if ($WindowHashTable.RunspaceRunning -ne $true) {
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
	    $SessionState.ApartmentState = "STA"
	    $SessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'WindowHashTable', $WindowHashTable, ""))
        $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 5, $SessionState, $Host)
	    $RunspacePool.Open()
        $PSCreate = [Powershell]::Create().AddScript($Scriptblock).AddArgument($LogFileList).AddArgument($TemplateText)
        $PSCreate.RunspacePool = $RunspacePool
        $PSCreate.BeginInvoke()
    }
}


[xml]$xaml = @'
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:PowerShell_WPF.Windows"
        
        Title="Universal Log Viewer" Height="500" Width="600" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="1*"/>
            <ColumnDefinition Width="5"/>
            <ColumnDefinition Width="2*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="30"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="4" Grid.RowSpan="4">
            <TextBox />
        </Grid>
        <Button Name="Btn_ChooseLogFiles" Content="Choose Log Files" Margin="5,5,5,5" Grid.Column="0" Grid.Row="0"/>
        <ListBox Name="List_LogFiles"  Grid.Row="1" Grid.Column="0" Grid.RowSpan="2" ItemsSource="{Binding Path=LogFileList}" Margin="5,5,0,5" SelectionMode="Extended">
            <ListBox.ContextMenu>
                <ContextMenu>
                    <MenuItem Name="LogFileRemove" Header="Remove"/>
                </ContextMenu>
            </ListBox.ContextMenu>
        </ListBox>
        <GridSplitter Grid.Column="1" HorizontalAlignment="Stretch" Grid.Row="0" Grid.RowSpan="2"/>
        <Grid Grid.Row="0" Grid.RowSpan="2" Grid.Column="2">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="30"/>
            </Grid.RowDefinitions>
            <Expander Header="Template" Grid.Row="0" Grid.Column="1" >
                <Grid Background="#FFE5E5E5" Height="200">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="25"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="30"/>
                    </Grid.RowDefinitions>
                    <Label Content="Template Text" HorizontalAlignment="Center" Grid.Row="0" Grid.Column="1"/>
                    <TextBox Text="{Binding Path=TemplateText}" Grid.Column="1" Grid.Row="1" AcceptsReturn="True" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"/>
                    <StackPanel Grid.Row="2" Grid.Column="1" Margin="0,5,0,0" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button Name="Btn_SaveTemplate" Width="75" Content="Save" Margin="0,0,5,0"/>
                        <Button Name="Btn_LoadTemplate" Width="75" Content="Load" Margin="0,0,5,0"/>
                        <Button Name="Btn_ApplyTemplate" Width="75" Content="Update" Margin="0,0,5,0"/>
                    </StackPanel>
                </Grid>
            </Expander>
            <DataGrid Grid.Row="1" ItemsSource="{Binding Path=LogDataGrid}" AutoGenerateColumns="True" IsReadOnly="True" CanUserAddRows="False"/>
            <Button Name="Btn_Refresh" Grid.Row="2" Width="75" Content="Refresh" Margin="0,5,0,5"/>
            <Label Grid.Row="2" HorizontalAlignment="Left" Content="{Binding Path=ProgressText}"/>
        </Grid>
    </Grid>
</Window>

'@

# Make window
$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xaml.SelectNodes("//*[@Name]") | Foreach-Object { Set-Variable -Name (("Window" + "_" + $_.Name)) -Value $Window.FindName($_.Name) }

Add-Type -Language CSharp @'
using System.ComponentModel;

public class WindowClass : INotifyPropertyChanged
{


    private string privateTemplateText;
    public string TemplateText
    {
        get { return privateTemplateText; }
        set
        {
            privateTemplateText = value;
            NotifyPropertyChanged("TemplateText");
        }
    }
    
    private object privateLogFileList;
    public object LogFileList
    {
        get { return privateLogFileList; }
        set
        {
            privateLogFileList = value;
            NotifyPropertyChanged("LogFileList");
        }
    }

    private object privateProgressText;
    public object ProgressText
    {
        get { return privateProgressText; }
        set
        {
            privateProgressText = value;
            NotifyPropertyChanged("ProgressText");
        }
    }

    private object privateExampleList;
    public object ExampleList
    {
        get { return privateExampleList; }
        set
        {
            privateExampleList = value;
            NotifyPropertyChanged("ExampleList");
        }
    }

    private object privateLogDataGrid;
    public object LogDataGrid
    {
        get { return privateLogDataGrid; }
        set
        {
            privateLogDataGrid = value;
            NotifyPropertyChanged("LogDataGrid");
        }
    }

    public event PropertyChangedEventHandler PropertyChanged;
    private void NotifyPropertyChanged(string property)
    {
        if(PropertyChanged != null)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(property));
        }
    }
}

'@
$WindowHashTable = [hashtable]::Synchronized(@{})
$WindowHashTable.WindowDataContext = New-Object -TypeName WindowClass
$Window.DataContext = $WindowHashTable.WindowDataContext
$WindowHashTable.WindowDataContext.ExampleList = New-Object System.Collections.ArrayList
#endregion
 
$Window_Btn_ChooseLogFiles.Add_Click({
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Filter = 'All files (*.*)|*.*'
    $OpenFileDialog.ShowDialog()
    $WindowHashTable.WindowDataContext.LogFileList += $OpenFileDialog.FileNames
})

$Window_LogFileRemove.Add_Click({
    $LogArray = $WindowHashTable.WindowDataContext.LogFileList
    $SelectedItems = $Window_List_LogFiles.SelectedItems
    if ($SelectedItems -eq $null) {
        $SelectedItems = $Window_List_LogFiles.SelectedItem
    }
    $TempArray = @()
    foreach ($Log in $LogArray) {
        $found = $false
        Write-Host $log
        foreach($Item in $SelectedItems) {
            Write-Host "$Item - $Log"
            if ($Item -eq $Log) { $found = $true }
        }
        if (!$found) { $TempArray += @($log) }
    }
    $WindowHashTable.WindowDataContext.LogFileList = $TempArray
})

$Window_Btn_LoadTemplate.Add_Click({
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Multiselect = $false
    $OpenFileDialog.Filter = 'All files (*.*)|*.*'
    $OpenFileDialog.ShowDialog()
    If (![String]::IsNullOrEmpty($OpenFileDialog.FileName)) {
        try {
            $WindowHashTable.WindowDataContext.TemplateText = ""
            Get-Content $OpenFileDialog.FileName | ForEach-Object {
                $WindowHashTable.WindowDataContext.TemplateText = $WindowHashTable.WindowDataContext.TemplateText + $_ + "`n"
            }
            
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            $Popup = New-Object -ComObject wscript.shell
            $Popup.Popup("Error loading file!`n$ErrorMessage",0,"Error!",16)
        }
    }
})
  
$Window_Btn_SaveTemplate.Add_Click({
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.OverwritePrompt = $true
    $SaveFileDialog.Filter = 'All files (*.*)|*.*'
    $SaveFileDialog.ShowDialog()
    If (![String]::IsNullOrEmpty($SaveFileDialog.FileName)) {
        $WindowHashTable.WindowDataContext.TemplateText > $SaveFileDialog.FileName
    }
})

$Window_Btn_ApplyTemplate.Add_Click({
    Update-EphingTemplate -LogFileList $WindowHashTable.WindowDataContext.LogFileList -TemplateText $WindowHashTable.WindowDataContext.TemplateText
})

$Window_Btn_Refresh.Add_Click({
    Update-EphingTemplate -LogFileList $WindowHashTable.WindowDataContext.LogFileList -TemplateText $WindowHashTable.WindowDataContext.TemplateText
})
 
$Window.ShowDialog() | Out-Null
