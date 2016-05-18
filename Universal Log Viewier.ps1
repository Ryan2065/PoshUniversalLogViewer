Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

Function Create-EphingClass {
    Param (
        $ClassName,
        $ClassHash
    )

    $Class = @"
using System.ComponentModel;
using System.Windows;
public class $ClassName : INotifyPropertyChanged
{

"@
    Foreach ($Key in $ClassHash.Keys) {
        $ClassType = $ClassHash[$Key]
        $Class = $Class + @"
        private $ClassType private$Key;
        public $ClassType $key
        {
            get { return private$Key; }
            set
            {
                private$Key = value;
                NotifyPropertyChanged("$Key");
            }
        }
"@
    }
$Class = $Class + @"

    public event PropertyChangedEventHandler PropertyChanged;
    private void NotifyPropertyChanged(string property)
    {
        if(PropertyChanged != null)
        {
            PropertyChanged(this, new PropertyChangedEventArgs(property));
        }
    }
}
"@
    try {
        $null = Add-Type -Language CSharp $Class -ErrorAction SilentlyContinue
        
    }
    catch {
        
    }
}

Function Update-EphingTemplate {
    Param ( 
        $LogFileList,
        $TemplateText
    )
    $WindowHashTable.WindowDataContext.ProgressText = 'Please wait...'
    try {
        $WindowHashTable.WindowDataContext.LogDataGrid = (Get-Content $LogFileList) | ConvertFrom-String -TemplateContent $TemplateText
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        $Popup = New-Object -ComObject wscript.shell
        $Popup.Popup("Error!`n$ErrorMessage",0,"Error!",16)
    }
    $WindowHashTable.WindowDataContext.ProgressText = 'Done!'
}

$ClassHash = @{
    'LogFileList'='object'
    'TemplateText'='string'
    'LogDataGrid'='object'
    'ProgressText'='string'
}

Create-EphingClass -ClassName 'WindowClass' -ClassHash $ClassHash

$WindowHashTable = [hashtable]::Synchronized(@{})
$WindowHashTable.Host = $Host
$WindowHashTable.WindowDataContext = New-Object -TypeName WindowClass
$Runspace = [RunspaceFactory]::CreateRunspace()
$Runspace.ApartmentState = "STA"
$Runspace.ThreadOptions = "ReuseThread"
$Runspace.Open()
$Runspace.SessionStateProxy.SetVariable("WindowHashTable",$WindowHashTable)
$psScript = [Powershell]::Create().AddScript({

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
        <ListBox Name="List_LogFiles" Grid.Row="1" Grid.Column="0" ItemsSource="{Binding Path=LogFileList}" Margin="5,5,0,5" SelectionMode="Extended">
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
                    <Label Content="Template Text" HorizontalAlignment="Center" Grid.Row="0"/>
                    <TextBox Text="{Binding Path=TemplateText}" Grid.Row="1" AcceptsReturn="True" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"/>
                    <StackPanel Grid.Row="2" Margin="0,5,0,0" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button Name="Btn_SaveTemplate" Width="75" Content="Save" Margin="0,0,5,0"/>
                        <Button Name="Btn_LoadTemplate" Width="75" Content="Load" Margin="0,0,5,0"/>
                        <Button Name="Btn_ApplyTemplate" Width="75" Content="Update" Margin="0,0,5,0"/>
                    </StackPanel>
                </Grid>
            </Expander>
            <DataGrid Grid.Row="1" ItemsSource="{Binding Path=LogDataGrid, Mode=TwoWay}" AutoGenerateColumns="True" IsReadOnly="True" CanUserAddRows="False"/>
            <Button Name="Btn_Refresh" Grid.Row="2" Width="75" Content="Refresh" Margin="0,5,5,5" HorizontalAlignment="Right"/>
            <Label Grid.Row="2" HorizontalAlignment="Left" Content="{Binding Path=ProgressText}"/>
        </Grid>
    </Grid>
</Window>

'@

$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xaml.SelectNodes("//*[@Name]") | Foreach-Object { Set-Variable -Name (("Window" + "_" + $_.Name)) -Value $Window.FindName($_.Name) }
$Window.DataContext = $WindowHashTable.WindowDataContext

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
    $WindowHashTable.Host.Runspace.Events.GenerateEvent("UpdateTemplate", $null, $null, "")
})

$Window_Btn_Refresh.Add_Click({
    $null = $WindowHashTable.Host.Runspace.Events.GenerateEvent("UpdateTemplate", $null, $null, "")
})

$Window.ShowDialog() | Out-Null

})

$psScript.Runspace = $Runspace
$Handle = $psScript.BeginInvoke()

while ($StopTheMadness -ne $true) {
    Start-Sleep 1
    $null = Wait-Event -SourceIdentifier 'UpdateTemplate'
    $null = Update-EphingTemplate -LogFileList $WindowHashTable.WindowDataContext.LogFileList -TemplateText $WindowHashTable.WindowDataContext.TemplateText
    $null = [System.GC]::Collect()
    $null = Remove-Event -SourceIdentifier 'UpdateTemplate'
}