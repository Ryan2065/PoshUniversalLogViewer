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
                        <RowDefinition Height="25"/>
                    </Grid.RowDefinitions>
                    <Label Content="Template Text" HorizontalAlignment="Center" Grid.Row="0" Grid.Column="1"/>
                    <TextBox Text="{Binding Path=TemplateText}" Grid.Column="1" Grid.Row="1" AcceptsReturn="True" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"/>
                    <Button Name="Btn_ApplyTemplate" Grid.Row="2" Grid.Column="1" Width="150" Content="Apply Template"/>
                </Grid>
            </Expander>
            <DataGrid Grid.Row="1" ItemsSource="{Binding Path=LogDataGrid}" AutoGenerateColumns="True" IsReadOnly="True" CanUserAddRows="False"/>
            <Button Name="Btn_Refresh" Grid.Row="2" Width="75" Content="Refresh" Margin="0,5,0,5"/>
            <Label Grid.Row="2" HorizontalAlignment="Left" Content="{Binding Path=ProgressText}"/>
        </Grid>
    </Grid>
</Window>

'@
# Add assemblies
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

Function Apply-EphingTemplate {
    Param ( 
        $LogFileList,
        $TemplateText
    )
    $Scriptblock = {
        $LogFileList = $args[0]
        $TemplateText = $args[1]
        $WindowHashTable.RunspaceRunning = $true
        $WindowHashTable.WindowDataContext.ProgressText = 'Please wait...'
        $LogContent = Get-Content $LogFileList
        $WindowHashTable.WindowDataContext.LogDataGrid = $LogContent | ConvertFrom-String -TemplateContent $TemplateText
        $WindowHashTable.RunSpaceRunning = $false
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

# Make window
$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xaml.SelectNodes("//*[@Name]") | Foreach-Object { Set-Variable -Name (("Window" + "_" + $_.Name)) -Value $Window.FindName($_.Name) }
#region CreateClass
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

    private object[] privateLogDataGrid;
    public object[] LogDataGrid
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

$Window_Btn_ApplyTemplate.Add_Click({
    Apply-EphingTemplate -LogFileList $WindowHashTable.WindowDataContext.LogFileList -TemplateText $WindowHashTable.WindowDataContext.TemplateText
})
  
$Window_Btn_Refresh.Add_Click({
    
})
 
$Window.ShowDialog() | Out-Null
