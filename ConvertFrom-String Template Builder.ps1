
[xml]$xaml = @'
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:PowerShell_WPF.Windows"
        Title="Template Builder" Height="500" Width="500" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="100"/>
            <ColumnDefinition Width="100"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="27"/>
            <RowDefinition Height="1*"/>
            <RowDefinition Height="27"/>
            <RowDefinition Height="3*"/>
            <RowDefinition Height="27"/>
            <RowDefinition Height="1*"/>
        </Grid.RowDefinitions>
        <Label Content="Original Template Text" Grid.ColumnSpan="3" Grid.Column="0" Grid.Row="0" HorizontalContentAlignment="Center"/>
        <TextBox Name="Txt_TemplateText" Grid.ColumnSpan="3" Grid.Row="1" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Text="{Binding Path=OriginalTemplateText}" AcceptsReturn="True"/>
        <StackPanel Orientation="Horizontal" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3">
            <Label Content="Number of Examples:" Margin="0,3,0,0"/>
            <TextBox Name="Txt_NumberofExamples" Width="50" VerticalContentAlignment="Center" Margin="0,3,0,0" Text="{Binding Path=NumberOfExamples}"/>
            <Label Content="Number of Columns:" Margin="0,3,0,0"/>
            <TextBox Name="Txt_NumberofColumns" Width="50" VerticalContentAlignment="Center" Margin="0,3,0,0" Text="{Binding Path=NumberOfColumns}"/>
        </StackPanel>
        <GroupBox Header="Examples" Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="3">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="25"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="25"/>
                    <RowDefinition Height="25"/>
                    <RowDefinition Height="25"/>
                    <RowDefinition Height="25"/>
                </Grid.RowDefinitions>
                <Label Content="Example" HorizontalContentAlignment="Center"/>
                <ListBox Name="List_Examples" SelectedIndex="{Binding Path=ExampleIndex, Mode=TwoWay}" ItemsSource="{Binding Path=ExampleList}" Grid.Row="1" Grid.RowSpan="6" Grid.Column="0" Margin="0,5,2,5"/>
                <Label Content="Column" HorizontalContentAlignment="Center" Grid.Column="1"/>
                <ListBox Name="List_Columns" SelectedIndex="{Binding Path=ColumnIndex, Mode=TwoWay}" ItemsSource="{Binding Path=ColumnList}" Grid.Column="1" Grid.RowSpan="6" Grid.Row="1" Margin="2,5,2,5"/>
                <Label Content="{Binding Path=Lbl_ExampleText}" HorizontalContentAlignment="Center" Grid.Row="0" Grid.Column="2"/>
                <TextBox Name="Txt_Example" Text="{Binding Path=ExampleText}" AcceptsReturn="True" Grid.Row="1" Grid.Column="2"/>
                <Label Content="{Binding Path=Lbl_ColumnName}" HorizontalContentAlignment="Center" Grid.Row="2" Grid.Column="2"/>
                <TextBox Name="Txt_ColumnName" Text="{Binding Path=ColumnName}" Height="25" VerticalContentAlignment="Center" Grid.Row="3" Grid.Column="2"/>
                <Label Content="{Binding Path=Lbl_ColumnTemplate}" HorizontalContentAlignment="Center" Grid.Row="4" Grid.Column="2"/>
                <TextBox Name="Txt_ColumnTemplate" Text="{Binding Path=ColumnTemplate}" Height="25" VerticalContentAlignment="Center" Grid.Row="5" Grid.Column="2"/>
            </Grid>
        </GroupBox>
        <Label Content="Modified Template Text" Grid.ColumnSpan="3" Grid.Column="0" Grid.Row="4" HorizontalContentAlignment="Center" Margin="0,0,0,0"/>
        <Button Name="Btn_Generate" Grid.Row="4" Grid.Column="2" Content="Generate" Width="75" HorizontalAlignment="Right" Margin="0,2,5,2"/>
        <TextBox Name="Txt_ModifiedTemplateText" Grid.ColumnSpan="3" Grid.Row="5" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" Text="{Binding Path=ModifiedTemplateText}" Margin="5,0,5,5"/>
    </Grid>
</Window>

'@

# Add assemblies
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase

# Make window
$Builder = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xaml.SelectNodes("//*[@Name]") | Foreach-Object { Set-Variable -Name (("Builder" + "_" + $_.Name)) -Value $Builder.FindName($_.Name) }
#region CreateClass
Add-Type -Language CSharp @'
using System.ComponentModel;
public class BuilderClass : INotifyPropertyChanged
{
    private string privateLbl_ExampleText;
    public string Lbl_ExampleText
    {
        get { return privateLbl_ExampleText; }
        set
        {
            privateLbl_ExampleText = value;
            NotifyPropertyChanged("Lbl_ExampleText");
        }
    }

    private string privateLbl_ColumnName;
    public string Lbl_ColumnName
    {
        get { return privateLbl_ColumnName; }
        set
        {
            privateLbl_ColumnName = value;
            NotifyPropertyChanged("Lbl_ColumnName");
        }
    }

    private string privateLbl_ColumnTemplate;
    public string Lbl_ColumnTemplate
    {
        get { return privateLbl_ColumnTemplate; }
        set
        {
            privateLbl_ColumnTemplate = value;
            NotifyPropertyChanged("Lbl_ColumnTemplate");
        }
    }

    private string privateOriginalTemplateText;
    public string OriginalTemplateText
    {
        get { return privateOriginalTemplateText; }
        set
        {
            privateOriginalTemplateText = value;
            NotifyPropertyChanged("OriginalTemplateText");
        }
    }

    private string privateNumberOfExamples;
    public string NumberOfExamples
    {
        get { return privateNumberOfExamples; }
        set
        {
            privateNumberOfExamples = value;
            NotifyPropertyChanged("NumberOfExamples");
        }
    }

    private string privateNumberOfColumns;
    public string NumberOfColumns
    {
        get { return privateNumberOfColumns; }
        set
        {
            privateNumberOfColumns = value;
            NotifyPropertyChanged("NumberOfColumns");
        }
    }

    private string privateExampleText;
    public string ExampleText
    {
        get { return privateExampleText; }
        set
        {
            privateExampleText = value;
            NotifyPropertyChanged("ExampleText");
        }
    }
    
    private int privateExampleIndex;
    public int ExampleIndex
    {
        get { return privateExampleIndex; }
        set
        {
            privateExampleIndex = value;
            NotifyPropertyChanged("ExampleIndex");
        }
    }
    
    private int privateColumnIndex;
    public int ColumnIndex
    {
        get { return privateColumnIndex; }
        set
        {
            privateColumnIndex = value;
            NotifyPropertyChanged("ColumnIndex");
        }
    }

    private string privateColumnName;
    public string ColumnName
    {
        get { return privateColumnName; }
        set
        {
            privateColumnName = value;
            NotifyPropertyChanged("ColumnName");
        }
    }

    private string privateColumnTemplate;
    public string ColumnTemplate
    {
        get { return privateColumnTemplate; }
        set
        {
            privateColumnTemplate = value;
            NotifyPropertyChanged("ColumnTemplate");
        }
    }

    private string privateModifiedTemplateText;
    public string ModifiedTemplateText
    {
        get { return privateModifiedTemplateText; }
        set
        {
            privateModifiedTemplateText = value;
            NotifyPropertyChanged("ModifiedTemplateText");
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

    private object privateColumnList;
    public object ColumnList
    {
        get { return privateColumnList; }
        set
        {
            privateColumnList = value;
            NotifyPropertyChanged("ColumnList");
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
#endregion

$BuilderDataContext = New-Object -TypeName 'BuilderClass'
$Builder.DataContext = $BuilderDataContext
$BuilderDataContext.Lbl_ExampleText = 'Example Text'
$BuilderDataContext.Lbl_ColumnName = 'Column Name'
$BuilderDataContext.Lbl_ColumnTemplate = 'Column Template'
$ExampleHash = @{}
$ColumnNameHash = @{}
$ColumnTemplateHash = @{}
$Script:ChangeSomething = $true

$Builder_Txt_NumberofExamples.Add_TextChanged({
    $Script:ChangeSomething = $false
    try {
        $count = 0
        $BuilderDataContext.ExampleList = @()
        $NumberOfExamples = $Builder_Txt_NumberofExamples.Text
        $NumberOfColumns = $Builder_Txt_NumberofColumns.Text
        while ($count -lt [int]$NumberOfExamples) {
            $count++
            $BuilderDataContext.ExampleList += @("Example $count")
        }
    }
    catch {
        $Popup = New-Object -ComObject wscript.shell
        $ErrorMessage = $_.Exception.Message
        $Popup.Popup("Error, Number of Examples needs to be a number!`n$ErrorMessage",0,"Error!",16)
    }
    $Script:ChangeSomething = $true
})

$Builder_Txt_NumberofColumns.Add_TextChanged({
    $Script:ChangeSomething = $false
    $NumberOfColumns = $Builder_Txt_NumberofColumns.Text
    try {
        $count = 0
        $BuilderDataContext.ColumnList = @()
        while ($count -lt [int]$NumberOfColumns) {
            $count++
            $BuilderDataContext.ColumnList += @("Column $count")
        }
    }
    catch {
        $Popup = New-Object -ComObject wscript.shell
        $ErrorMessage = $_.Exception.Message
        $Popup.Popup("Error, Number of Columns needs to be a number!`n$ErrorMessage",0,"Error!",16)
    }
    $Script:ChangeSomething = $true
})

$Builder_Txt_Example.Add_TextChanged({
    if ($Script:ChangeSomething) {
        $ExampleIndex = $BuilderDataContext.ExampleIndex
        $ExampleHash[$ExampleIndex] = $Builder_Txt_Example.Text
    }
})

$Builder_Txt_ColumnName.Add_TextChanged({
    if ($Script:ChangeSomething) {
        $ColumnIndex = $BuilderDataContext.ColumnIndex
        $ColumnNameHash[$ColumnIndex] = $Builder_Txt_ColumnName.Text
    }
})

$Builder_Txt_ColumnTemplate.Add_TextChanged({
    if ($Script:ChangeSomething) {
        $ColumnIndex = $BuilderDataContext.ColumnIndex
        $ExampleIndex = $BuilderDataContext.ExampleIndex
        $HashIndex = "$ExampleIndex" + "$ColumnIndex"
        $ColumnTemplateHash[$HashIndex] = $Builder_Txt_ColumnTemplate.Text
    }
})

$Builder_List_Examples.Add_SelectionChanged({
    $Script:ChangeSomething = $false
    $ColumnIndex = $BuilderDataContext.ColumnIndex
    $ExampleIndex = $BuilderDataContext.ExampleIndex
    $HashIndex = "$ExampleIndex" + "$ColumnIndex"
    $BuilderDataContext.ColumnName = $ColumnNameHash[$ColumnIndex]
    $BuilderDataContext.ColumnTemplate = $ColumnTemplateHash[$HashIndex]
    $BuilderDataContext.ExampleText = $ExampleHash[$ExampleIndex]
    $Script:ChangeSomething = $true
})

$Builder_List_Columns.Add_SelectionChanged({
    $Script:ChangeSomething = $false
    $ColumnIndex = $BuilderDataContext.ColumnIndex
    $ExampleIndex = $BuilderDataContext.ExampleIndex
    $HashIndex = "$ExampleIndex" + "$ColumnIndex"
    $BuilderDataContext.ColumnName = $ColumnNameHash[$ColumnIndex]
    $BuilderDataContext.ColumnTemplate = $ColumnTemplateHash[$HashIndex]
    $BuilderDataContext.ExampleText = $ExampleHash[$ExampleIndex]
    $Script:ChangeSomething = $true
})

$Builder_Btn_Generate.Add_Click({
    $BuilderDataContext.ModifiedTemplateText = $BuilderDataContext.OriginalTemplateText.replace('/','//').replace('{','/{').replace('}','/}')
    foreach ($ExampleKey in $ExampleHash.Keys){
        $ExampleText = $ExampleHash[$ExampleKey]
        $ExampleText = $ExampleText.replace('/','//').replace('{','/{').replace('}','/}')
        $ModifiedExampleText = $ExampleText
        foreach ($ColumnKey in $ColumnNameHash.Keys) {
            $ColumnName = $ColumnNameHash[$ColumnKey]
            $HashIndex = "$ExampleKey" + "$ColumnKey"
            $ColumnTemplate = $ColumnTemplateHash[$HashIndex]
            $ColumnTemplate = $ColumnTemplate.replace('/','//').replace('{','/{').replace('}','/}')
            $ModifiedColumnTemplate = ''
            if ($ColumnKey -eq 0) {
                $ModifiedColumnTemplate = '{' + $ColumnName + '*:' + $ColumnTemplate + '}'
            }
            else {
                $ModifiedColumnTemplate = '{' + $ColumnName + ':' + $ColumnTemplate + '}'
            }
            $ModifiedExampleText = $ModifiedExampleText.Replace($ColumnTemplate,$ModifiedColumnTemplate)
        }
        $BuilderDataContext.ModifiedTemplateText = $BuilderDataContext.ModifiedTemplateText.Replace($ExampleText,$ModifiedExampleText)
    }
})

$Builder.ShowDialog() | Out-Null
