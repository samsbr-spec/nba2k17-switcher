# NBA 2K17 Launcher - the window (Y2K edition). Two tiles: Revival and Back2Back. Clicking one parks the other
# client's saves, puts the chosen client's saves in place and starts that client. Engine: Switcher.Core.ps1.
$ErrorActionPreference = 'Stop'
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}
. (Join-Path $PSScriptRoot 'Switcher.Core.ps1')
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$script:NoWait = $true

# A 12-point starburst for the stickers.
$starPts = @()
for ($i = 0; $i -lt 24; $i++) {
    $r = if ($i % 2 -eq 0) { 50 } else { 38 }
    $a = $i * [math]::PI / 12
    $starPts += ('{0:0.#},{1:0.#}' -f (50 + $r * [math]::Sin($a)), (50 - $r * [math]::Cos($a)))
}
$star = $starPts -join ' '

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="NBA 2K17 Launcher" Width="900" Height="640" MinWidth="760" MinHeight="560"
        WindowStartupLocation="CenterScreen" FontFamily="Segoe UI" Foreground="White">
  <Window.Resources>
    <LinearGradientBrush x:Key="SkyBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#7FD6FF" Offset="0"/>
      <GradientStop Color="#2A8FE0" Offset="0.45"/>
      <GradientStop Color="#0D3B7A" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="LavaBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#FFB347" Offset="0"/>
      <GradientStop Color="#FF6A13" Offset="0.5"/>
      <GradientStop Color="#C8290A" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="SharkBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#7EEBFF" Offset="0"/>
      <GradientStop Color="#1FA3E0" Offset="0.5"/>
      <GradientStop Color="#0A4C9E" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="GlossBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#99FFFFFF" Offset="0"/>
      <GradientStop Color="#22FFFFFF" Offset="0.85"/>
      <GradientStop Color="#00FFFFFF" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="ShineBrush" StartPoint="0,0" EndPoint="1,0">
      <GradientStop Color="#00FFFFFF" Offset="0"/>
      <GradientStop Color="#AAFFFFFF" Offset="0.5"/>
      <GradientStop Color="#00FFFFFF" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="TitleBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#FFFFFF" Offset="0"/>
      <GradientStop Color="#FFF1B8" Offset="0.55"/>
      <GradientStop Color="#FFB94A" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="PillBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#FFFFFF" Offset="0"/>
      <GradientStop Color="#E3E8EE" Offset="0.5"/>
      <GradientStop Color="#B9C4D1" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="PillHotBrush" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#FFFFFF" Offset="0"/>
      <GradientStop Color="#FFE9A8" Offset="0.5"/>
      <GradientStop Color="#FFC24A" Offset="1"/>
    </LinearGradientBrush>
    <RadialGradientBrush x:Key="BallBrush" GradientOrigin="0.35,0.3" Center="0.45,0.4" RadiusX="0.7" RadiusY="0.7">
      <GradientStop Color="#FFC88A" Offset="0"/>
      <GradientStop Color="#F07A1E" Offset="0.55"/>
      <GradientStop Color="#9A3A08" Offset="1"/>
    </RadialGradientBrush>
    <RadialGradientBrush x:Key="BubbleBrush" GradientOrigin="0.3,0.3" Center="0.5,0.5" RadiusX="0.5" RadiusY="0.5">
      <GradientStop Color="#55FFFFFF" Offset="0"/>
      <GradientStop Color="#11FFFFFF" Offset="0.7"/>
      <GradientStop Color="#33FFFFFF" Offset="1"/>
    </RadialGradientBrush>

    <Style x:Key="Tile" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="root" Background="{TemplateBinding Background}" BorderBrush="#B3FFFFFF" BorderThickness="2" CornerRadius="24" RenderTransformOrigin="0.5,0.5">
              <Border.RenderTransform>
                <ScaleTransform x:Name="scale" ScaleX="1" ScaleY="1"/>
              </Border.RenderTransform>
              <Border.Effect>
                <DropShadowEffect x:Name="shadow" Color="#000000" Opacity="0.55" BlurRadius="18" ShadowDepth="6"/>
              </Border.Effect>
              <Grid ClipToBounds="True">
                <Border CornerRadius="22,22,60,60" Background="{StaticResource GlossBrush}" VerticalAlignment="Top" Height="78" Margin="6,2,6,0"/>
                <Rectangle x:Name="shine" Width="160" HorizontalAlignment="Left" Fill="{StaticResource ShineBrush}" Opacity="0.7">
                  <Rectangle.RenderTransform>
                    <TransformGroup>
                      <SkewTransform AngleX="-22"/>
                      <TranslateTransform x:Name="shineMove" X="-260"/>
                    </TransformGroup>
                  </Rectangle.RenderTransform>
                </Rectangle>
                <ContentPresenter Margin="26,22,26,22" HorizontalAlignment="Stretch" VerticalAlignment="Top"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <EventTrigger RoutedEvent="MouseEnter">
                <BeginStoryboard>
                  <Storyboard>
                    <DoubleAnimation Storyboard.TargetName="scale" Storyboard.TargetProperty="ScaleX" To="1.025" Duration="0:0:0.18"/>
                    <DoubleAnimation Storyboard.TargetName="scale" Storyboard.TargetProperty="ScaleY" To="1.025" Duration="0:0:0.18"/>
                    <DoubleAnimation Storyboard.TargetName="shadow" Storyboard.TargetProperty="BlurRadius" To="36" Duration="0:0:0.18"/>
                    <DoubleAnimation Storyboard.TargetName="shineMove" Storyboard.TargetProperty="X" From="-260" To="1400" Duration="0:0:0.75"/>
                  </Storyboard>
                </BeginStoryboard>
              </EventTrigger>
              <EventTrigger RoutedEvent="MouseLeave">
                <BeginStoryboard>
                  <Storyboard>
                    <DoubleAnimation Storyboard.TargetName="scale" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.18"/>
                    <DoubleAnimation Storyboard.TargetName="scale" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.18"/>
                    <DoubleAnimation Storyboard.TargetName="shadow" Storyboard.TargetProperty="BlurRadius" To="18" Duration="0:0:0.18"/>
                  </Storyboard>
                </BeginStoryboard>
              </EventTrigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="root" Property="Opacity" Value="0.9"/>
                <Setter TargetName="root" Property="BorderBrush" Value="#FFFFFFFF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="root" Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Pill" TargetType="Button">
      <Setter Property="Foreground" Value="#1B2A44"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,0,10,0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="pill" Background="{StaticResource PillBrush}" BorderBrush="#88FFFFFF" BorderThickness="1" CornerRadius="18" Padding="18,8">
              <Border.Effect>
                <DropShadowEffect Color="#000000" Opacity="0.35" BlurRadius="8" ShadowDepth="2"/>
              </Border.Effect>
              <Grid>
                <Border CornerRadius="16,16,30,30" Background="{StaticResource GlossBrush}" VerticalAlignment="Top" Height="14" Margin="4,1,4,0"/>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="pill" Property="Background" Value="{StaticResource PillHotBrush}"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="pill" Property="Opacity" Value="0.8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Sticker" TargetType="Grid">
      <Setter Property="Width" Value="100"/>
      <Setter Property="Height" Value="100"/>
      <Setter Property="HorizontalAlignment" Value="Right"/>
      <Setter Property="VerticalAlignment" Value="Top"/>
      <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
    </Style>
  </Window.Resources>

  <Grid Background="{StaticResource SkyBrush}">
    <Canvas IsHitTestVisible="False">
      <Ellipse Width="420" Height="420" Canvas.Left="-140" Canvas.Top="-200" Opacity="0.35">
        <Ellipse.Fill>
          <RadialGradientBrush><GradientStop Color="#FFFFFF" Offset="0"/><GradientStop Color="#00FFFFFF" Offset="1"/></RadialGradientBrush>
        </Ellipse.Fill>
      </Ellipse>
      <Ellipse x:Name="Bubble1" Width="140" Height="140" Canvas.Left="640" Canvas.Top="60" Fill="{StaticResource BubbleBrush}" Stroke="#66FFFFFF" StrokeThickness="2">
        <Ellipse.RenderTransform><TranslateTransform x:Name="Bubble1Move"/></Ellipse.RenderTransform>
      </Ellipse>
      <Ellipse x:Name="Bubble2" Width="70" Height="70" Canvas.Left="800" Canvas.Top="240" Fill="{StaticResource BubbleBrush}" Stroke="#55FFFFFF" StrokeThickness="2">
        <Ellipse.RenderTransform><TranslateTransform x:Name="Bubble2Move"/></Ellipse.RenderTransform>
      </Ellipse>
      <Ellipse x:Name="Bubble3" Width="100" Height="100" Canvas.Left="80" Canvas.Top="430" Fill="{StaticResource BubbleBrush}" Stroke="#55FFFFFF" StrokeThickness="2">
        <Ellipse.RenderTransform><TranslateTransform x:Name="Bubble3Move"/></Ellipse.RenderTransform>
      </Ellipse>
      <Ellipse x:Name="Bubble4" Width="46" Height="46" Canvas.Left="420" Canvas.Top="520" Fill="{StaticResource BubbleBrush}" Stroke="#55FFFFFF" StrokeThickness="2">
        <Ellipse.RenderTransform><TranslateTransform x:Name="Bubble4Move"/></Ellipse.RenderTransform>
      </Ellipse>
    </Canvas>

    <Grid Margin="30,20,30,16">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="140"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,14">
        <Canvas Width="64" Height="64" Margin="0,2,16,0">
          <Canvas.RenderTransform><TranslateTransform x:Name="BallBounce"/></Canvas.RenderTransform>
          <Ellipse Width="60" Height="60" Canvas.Left="2" Canvas.Top="2" Fill="{StaticResource BallBrush}" Stroke="#5A2308" StrokeThickness="2">
            <Ellipse.Effect><DropShadowEffect Color="#000000" Opacity="0.5" BlurRadius="10" ShadowDepth="4"/></Ellipse.Effect>
          </Ellipse>
          <Path Stroke="#5A2308" StrokeThickness="2.2" Data="M32,2 L32,62 M2,32 L62,32 M12,9 Q30,32 12,55 M52,9 Q34,32 52,55"/>
          <Ellipse Width="16" Height="10" Canvas.Left="16" Canvas.Top="12" Fill="#66FFFFFF"/>
        </Canvas>
        <StackPanel VerticalAlignment="Center">
          <TextBlock Text="NBA 2K17" FontFamily="Impact, Arial Black, Segoe UI" FontSize="50" Foreground="{StaticResource TitleBrush}" Margin="0,-6,0,0">
            <TextBlock.Effect><DropShadowEffect Color="#0A2A5A" Opacity="0.8" BlurRadius="6" ShadowDepth="3"/></TextBlock.Effect>
          </TextBlock>
          <TextBlock x:Name="Subtitle" Text="Pick your server, hotshot. The right saves jump in before tip-off." FontSize="14" Foreground="#E6FFFFFF" Margin="2,-4,0,0">
            <TextBlock.Effect><DropShadowEffect Color="#0A2A5A" Opacity="0.6" BlurRadius="4" ShadowDepth="1"/></TextBlock.Effect>
          </TextBlock>
        </StackPanel>
      </StackPanel>

      <Grid Grid.Row="1">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="22"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button x:Name="RevivalTile" Grid.Column="0" Style="{StaticResource Tile}" Background="{StaticResource LavaBrush}">
          <Grid>
            <StackPanel>
              <TextBlock Text="REVIVAL" FontFamily="Impact, Arial Black, Segoe UI" FontSize="44" Foreground="White" Margin="0,0,96,0">
                <TextBlock.Effect><DropShadowEffect Color="#5A1A00" Opacity="0.8" BlurRadius="5" ShadowDepth="3"/></TextBlock.Effect>
              </TextBlock>
              <TextBlock Text="Packed park, 8x progression. A grind, but a quick one." FontSize="14" Foreground="#F2FFFFFF" Margin="0,2,96,16" TextWrapping="Wrap"/>
              <TextBlock x:Name="RevivalSaves" Text="" FontSize="12" Foreground="#E0FFFFFF" TextWrapping="Wrap"/>
              <TextBlock x:Name="RevivalHint" Text="" FontSize="12" Foreground="#FFF3B0" Margin="0,8,0,0" TextWrapping="Wrap"/>
            </StackPanel>
            <Grid Style="{StaticResource Sticker}" Margin="0,-6,-8,0">
              <Grid.RenderTransform><RotateTransform Angle="12"/></Grid.RenderTransform>
              <Polygon Points="$star" Fill="#FFE94D" Stroke="#FFFFFF" StrokeThickness="2">
                <Polygon.Effect><DropShadowEffect Color="#000000" Opacity="0.4" BlurRadius="6" ShadowDepth="2"/></Polygon.Effect>
              </Polygon>
              <TextBlock Text="FULL&#10;PARK!" FontFamily="Impact, Arial Black, Segoe UI" FontSize="17" Foreground="#B3270B" TextAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center" LineHeight="17" LineStackingStrategy="BlockLineHeight"/>
            </Grid>
          </Grid>
        </Button>
        <Button x:Name="Back2BackTile" Grid.Column="2" Style="{StaticResource Tile}" Background="{StaticResource SharkBrush}">
          <Grid>
            <StackPanel>
              <TextBlock Text="BACK2BACK" FontFamily="Impact, Arial Black, Segoe UI" FontSize="44" Foreground="White" Margin="0,0,96,0">
                <TextBlock.Effect><DropShadowEffect Color="#062C5A" Opacity="0.8" BlurRadius="5" ShadowDepth="3"/></TextBlock.Effect>
              </TextBlock>
              <TextBlock Text="96 OVR and every badge on day one. Chill courts, no grind." FontSize="14" Foreground="#F2FFFFFF" Margin="0,2,96,16" TextWrapping="Wrap"/>
              <TextBlock x:Name="Back2BackSaves" Text="" FontSize="12" Foreground="#E0FFFFFF" TextWrapping="Wrap"/>
              <TextBlock x:Name="Back2BackHint" Text="" FontSize="12" Foreground="#FFF3B0" Margin="0,8,0,0" TextWrapping="Wrap"/>
            </StackPanel>
            <Grid Style="{StaticResource Sticker}" Margin="0,-6,-8,0">
              <Grid.RenderTransform><RotateTransform Angle="-10"/></Grid.RenderTransform>
              <Polygon Points="$star" Fill="#FFE94D" Stroke="#FFFFFF" StrokeThickness="2">
                <Polygon.Effect><DropShadowEffect Color="#000000" Opacity="0.4" BlurRadius="6" ShadowDepth="2"/></Polygon.Effect>
              </Polygon>
              <TextBlock Text="96&#10;OVR" FontFamily="Impact, Arial Black, Segoe UI" FontSize="19" Foreground="#0A4C9E" TextAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center" LineHeight="19" LineStackingStrategy="BlockLineHeight"/>
            </Grid>
          </Grid>
        </Button>
      </Grid>

      <Border Grid.Row="2" Margin="0,16,0,10" CornerRadius="16" Background="#33FFFFFF" BorderBrush="#88FFFFFF" BorderThickness="1" Padding="16,9">
        <TextBlock x:Name="StatusText" FontSize="14" FontWeight="SemiBold" Foreground="White" TextWrapping="Wrap">
          <TextBlock.Effect><DropShadowEffect Color="#0A2A5A" Opacity="0.6" BlurRadius="3" ShadowDepth="1"/></TextBlock.Effect>
        </TextBlock>
      </Border>

      <Border Grid.Row="3" CornerRadius="14" Background="#66061A3A" BorderBrush="#55FFFFFF" BorderThickness="1" Padding="4">
        <TextBox x:Name="LogBox" IsReadOnly="True" Focusable="False" IsTabStop="False" Background="Transparent" BorderThickness="0" Foreground="#E8F4FF" FontFamily="Consolas" FontSize="12" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Padding="8,6"/>
      </Border>

      <DockPanel Grid.Row="4" Margin="0,14,0,0">
        <TextBlock x:Name="VersionText" DockPanel.Dock="Right" VerticalAlignment="Center" Foreground="#AAFFFFFF" FontSize="11"/>
        <StackPanel Orientation="Horizontal">
          <Button x:Name="SetupButton" Style="{StaticResource Pill}" Content="Re-run setup"/>
          <Button x:Name="SplitButton" Style="{StaticResource Pill}" Content="Split game folder"/>
          <Button x:Name="DataButton" Style="{StaticResource Pill}" Content="Saves vault"/>
          <Button x:Name="HelpButton" Style="{StaticResource Pill}" Content="How it works"/>
          <Button x:Name="UpdateButton" Style="{StaticResource Pill}" Content="Update" Visibility="Collapsed" FontWeight="Bold"/>
        </StackPanel>
      </DockPanel>
    </Grid>

    <TextBlock x:Name="GameOnText" Text="GAME ON!" FontFamily="Impact, Arial Black, Segoe UI" FontSize="120" Foreground="{StaticResource TitleBrush}" HorizontalAlignment="Center" VerticalAlignment="Center" Opacity="0" IsHitTestVisible="False" RenderTransformOrigin="0.5,0.5">
      <TextBlock.RenderTransform><ScaleTransform x:Name="GameOnScale" ScaleX="0.6" ScaleY="0.6"/></TextBlock.RenderTransform>
      <TextBlock.Effect><DropShadowEffect Color="#000000" Opacity="0.8" BlurRadius="18" ShadowDepth="6"/></TextBlock.Effect>
    </TextBlock>
  </Grid>
</Window>
"@

$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
foreach ($n in 'Subtitle', 'RevivalTile', 'Back2BackTile', 'RevivalSaves', 'Back2BackSaves', 'RevivalHint', 'Back2BackHint', 'StatusText', 'LogBox', 'VersionText', 'SetupButton', 'SplitButton', 'DataButton', 'HelpButton', 'UpdateButton', 'GameOnText', 'GameOnScale', 'BallBounce', 'Bubble1Move', 'Bubble2Move', 'Bubble3Move', 'Bubble4Move') {
    Set-Variable -Name $n -Value $window.FindName($n) -Scope Script
}
$VersionText.Text = "NBA 2K17 Switcher $script:Version  |  Y2K edition"
if (Test-Path $script:IconPath) { try { $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri $script:IconPath)) } catch {} }

function Start-Float($transform, [double]$By, [double]$Seconds) {
    $a = New-Object System.Windows.Media.Animation.DoubleAnimation
    $a.From = 0; $a.To = $By; $a.Duration = [TimeSpan]::FromSeconds($Seconds); $a.AutoReverse = $true
    $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $a.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $a)
}

function Show-GameOn {
    $fade = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $fade.Duration = [TimeSpan]::FromSeconds(1.9)
    $fade.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::Zero)))) | Out-Null
    $fade.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0.25))))) | Out-Null
    $fade.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(1.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(1.3))))) | Out-Null
    $fade.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(0.0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(1.9))))) | Out-Null
    $GameOnText.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fade)
    $grow = New-Object System.Windows.Media.Animation.DoubleAnimation
    $grow.From = 0.6; $grow.To = 1.15; $grow.Duration = [TimeSpan]::FromSeconds(1.9)
    $grow.EasingFunction = New-Object System.Windows.Media.Animation.BackEase
    $GameOnScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $grow)
    $GameOnScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $grow)
}

function Append-Log([string]$Text, [string]$Level = 'INFO') {
    $prefix = switch ($Level) { 'ERROR' { '!! ' } 'WARN' { '!  ' } default { '   ' } }
    $LogBox.AppendText(("{0:HH:mm:ss} {1}{2}`r`n" -f (Get-Date), $prefix, $Text))
    $LogBox.ScrollToEnd()
}
$script:Say = { param($Message, $Level) Append-Log $Message $Level }
$script:AskYesNo = { param($Prompt) return ([System.Windows.MessageBox]::Show($window, $Prompt, 'NBA 2K17 Launcher', 'YesNo', 'Question') -eq 'Yes') }
$script:AskThree = {
    param($Prompt, $LabelA, $LabelB)
    $r = [System.Windows.MessageBox]::Show($window, "$Prompt`n`nYes = $LabelA`nNo = $LabelB`nCancel = do nothing", 'NBA 2K17 Launcher', 'YesNoCancel', 'Question')
    switch ("$r") { 'Yes' { 'A' } 'No' { 'B' } default { 'Cancel' } }
}

function Show-Choice([string]$Text, [string[]]$Buttons) {
    $dlg = New-Object System.Windows.Window
    $dlg.Title = 'NBA 2K17 Launcher'; $dlg.Width = 540; $dlg.SizeToContent = 'Height'; $dlg.ResizeMode = 'NoResize'
    $dlg.WindowStartupLocation = 'CenterOwner'; $dlg.Background = $window.FindResource('SkyBrush'); $dlg.Foreground = 'White'; $dlg.FontFamily = 'Segoe UI'
    if ($window.IsVisible) { $dlg.Owner = $window }
    $sp = New-Object System.Windows.Controls.StackPanel; $sp.Margin = '24'
    $tb = New-Object System.Windows.Controls.TextBlock; $tb.Text = $Text; $tb.TextWrapping = 'Wrap'; $tb.FontSize = 14; $tb.Margin = '0,0,0,18'
    $sp.Children.Add($tb) | Out-Null
    $wp = New-Object System.Windows.Controls.WrapPanel
    $dlg.Tag = -1
    for ($i = 0; $i -lt $Buttons.Count; $i++) {
        $b = New-Object System.Windows.Controls.Button; $b.Content = $Buttons[$i]; $b.Tag = $i; $b.MinWidth = 130; $b.Style = $window.FindResource('Pill')
        $b.Add_Click({ param($s, $e) $w = [System.Windows.Window]::GetWindow($s); $w.Tag = $s.Tag; $w.DialogResult = $true })
        $wp.Children.Add($b) | Out-Null
    }
    $sp.Children.Add($wp) | Out-Null
    $dlg.Content = $sp
    [void]$dlg.ShowDialog()
    return [int]$dlg.Tag
}

function Refresh-View {
    try {
        $i = Get-StatusInfo
        if (-not $i.state) {
            $StatusText.Text = 'Not set up yet. Hit "Re-run setup" (one question) and you are good to go.'
            $RevivalTile.IsEnabled = $false; $Back2BackTile.IsEnabled = $false
            $RevivalSaves.Text = ''; $Back2BackSaves.Text = ''
            return
        }
        foreach ($c in 'Revival', 'Back2Back') {
            $savesTb = Get-Variable -Name "${c}Saves" -ValueOnly; $hintTb = Get-Variable -Name "${c}Hint" -ValueOnly
            if ($i.current -eq $c) { $savesTb.Text = "SUITED UP: these saves are in the Steam folder now ($($i.remoteDesc))" }
            else {
                $parked = if ($c -eq 'Revival') { $i.parkedRevival } else { $i.parkedBack2Back }
                $savesTb.Text = if ($parked -eq 'empty') { 'ON THE BENCH: nothing parked yet (first launch pulls its cloud copy)' } else { "ON THE BENCH: parked and ready ($parked)" }
            }
            $exe = if ($c -eq 'Revival') { $i.revivalExe } else { $i.back2backExe }
            $hintTb.Text = if ($exe) { '' } else { "$c is not installed on this PC." }
        }
        $gameMsg = if ($i.gameRunning) { 'NBA 2K17 is running. Finish the game before switching.' } elseif ($i.current -eq 'Back2Back' -and $i.b2bUpload -eq 'busy') { 'Back2Back is still saving to its cloud. Wait for "Progress saved" before switching.' } else { '' }
        $enabled = -not $i.gameRunning -and -not $i.shared
        $RevivalTile.IsEnabled = $enabled -and [bool]$i.revivalExe
        $Back2BackTile.IsEnabled = $enabled -and [bool]$i.back2backExe
        $line = "Suited up for: $($i.current)"
        if ($i.lastSwitch) { $line += "   (since $(([datetime]$i.lastSwitch).ToString('ddd HH:mm')))" }
        if ($gameMsg) { $line += "`n$gameMsg" }
        if ($i.shared) { $line += "`nOne-time setup left: both clients still use the SAME game folder. Close both launchers, then hit 'Split game folder' below. The tiles unlock when it's done." }
        $StatusText.Text = $line
    } catch {
        $StatusText.Text = "Could not read the current state: $($_.Exception.Message)"
    }
}

function Start-SplitConsole {
    # The split copies the whole game (5-15 minutes), so it runs in its own console window with live progress.
    Start-Process $script:PowerShellExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script:CliScript`" -Split" -WorkingDirectory $script:Root
    Append-Log 'Split started in a console window. The tiles unlock here as soon as it finishes.'
}

function Run-Setup {
    $i = Get-StatusInfo
    $splitOffered = $false
    if ($i.shared) {
        $c = Show-Choice ("One-time setup first: Revival and Back2Back both use the same game folder`n($($i.revivalGame)).`n`nThey overwrite each other's files there on every launch, so Back2Back needs its own copy of the game. A console window will copy it (5-15 minutes); both launchers and the game must be closed first.") @('Copy it now', 'Later')
        if ($c -eq 0) { Start-SplitConsole; $splitOffered = $true }
    }
    $choice = Show-Choice ("The Steam save folder currently holds: $($i.remoteDesc)`n`nWhich client did you play LAST on this PC? (That tells the launcher whose saves these are. Pick 'Not sure' if you've been switching by hand; each client will then pull its own cloud copy the first time.)") @('Revival', 'Back2Back', 'Not sure')
    if ($choice -lt 0) { return }
    $cur = @('Revival', 'Back2Back', 'Unknown')[$choice]
    try {
        [void](Invoke-Setup -CurrentClient $cur -SkipSplitOffer)
        $msg = "All set. Suited up for: $cur.`n`nFrom now on just click a tile."
        if ($splitOffered) { $msg = "Saves and icons are set up. When the console window says the copy is done:`n`n" + (Get-SplitAdvice) + "`n`nThe tiles unlock by themselves once the folders are separate." }
        [System.Windows.MessageBox]::Show($window, $msg, 'NBA 2K17 Launcher', 'OK', 'Information') | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show($window, ($_.Exception.Message -replace '^SWITCHER: ', ''), 'NBA 2K17 Launcher', 'OK', 'Error') | Out-Null
    }
    Refresh-View
}

function Start-Client([string]$Target) {
    $RevivalTile.IsEnabled = $false; $Back2BackTile.IsEnabled = $false
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $StatusText.Text = "Lacing up for $Target..."
    Append-Log "Lacing up for $Target..."
    $window.Dispatcher.Invoke([Action] {}, [System.Windows.Threading.DispatcherPriority]::Render)
    try {
        $r = Invoke-Play $Target
        $StatusText.Text = "Tip-off! $Target is starting. " + $r.advice
        Show-GameOn
    } catch {
        $msg = $_.Exception.Message -replace '^SWITCHER: ', ''
        Append-Log $msg 'ERROR'
        [System.Windows.MessageBox]::Show($window, $msg, 'NBA 2K17 Launcher', 'OK', 'Warning') | Out-Null
    } finally {
        $window.Cursor = $null
        Refresh-View
    }
}

$RevivalTile.Add_Click({ Start-Client 'Revival' })
$Back2BackTile.Add_Click({ Start-Client 'Back2Back' })
$SetupButton.Add_Click({ Run-Setup })
$SplitButton.Add_Click({
    if (Test-SharedGameFolder) {
        $ok = [System.Windows.MessageBox]::Show($window, "This copies the whole game folder (5-15 minutes) so Back2Back gets its own copy, then points Back2Back at it. Both launchers and the game must be closed.`n`nA console window will show progress. Start now?", 'NBA 2K17 Launcher', 'YesNo', 'Question')
        if ($ok -eq 'Yes') { Start-SplitConsole; [System.Windows.MessageBox]::Show($window, (Get-SplitAdvice), 'NBA 2K17 Launcher', 'OK', 'Information') | Out-Null }
    } else {
        [System.Windows.MessageBox]::Show($window, "Already split: Revival and Back2Back use different game folders. Nothing to do.", 'NBA 2K17 Launcher', 'OK', 'Information') | Out-Null
    }
})
$DataButton.Add_Click({ if (-not (Test-Path $script:AppDir)) { New-Item -ItemType Directory -Force $script:AppDir | Out-Null }; Start-Process explorer.exe $script:AppDir })
$HelpButton.Add_Click({ $readme = Join-Path $script:Root 'README.txt'; if (Test-Path $readme) { Start-Process notepad.exe "`"$readme`"" } })

# --- update check (runs in the background so the window never freezes while GitHub answers) ---
$script:UpdatePS = $null; $script:UpdateHandle = $null; $script:PendingUpdate = $null
function Start-UpdateCheck {
    if (-not (Get-UpdateSource)) { return }
    try {
        $script:UpdatePS = [powershell]::Create()
        [void]$script:UpdatePS.AddScript({ param($core) . $core; Get-UpdateInfo -TimeoutSec 8 }).AddArgument((Join-Path $script:Root 'Switcher.Core.ps1'))
        $script:UpdateHandle = $script:UpdatePS.BeginInvoke()
    } catch { $script:UpdatePS = $null; $script:UpdateHandle = $null }
}
function Poll-UpdateCheck {
    if (-not $script:UpdateHandle -or -not $script:UpdateHandle.IsCompleted) { return }
    $res = $null
    try { $res = $script:UpdatePS.EndInvoke($script:UpdateHandle) | Select-Object -Last 1 } catch {}
    try { $script:UpdatePS.Dispose() } catch {}
    $script:UpdatePS = $null; $script:UpdateHandle = $null
    if (-not $res -or -not $res.configured) { return }
    if ($res.error) { Append-Log "Update check skipped (no connection to GitHub right now)." 'WARN'; return }
    if ($res.available) {
        $script:PendingUpdate = $res
        $UpdateButton.Content = "Update to $($res.latest)"
        $UpdateButton.Visibility = 'Visible'
        Append-Log "Version $($res.latest) is out (you have $($res.local)). Click 'Update to $($res.latest)' when you're ready."
    } else {
        Append-Log "Up to date (version $($res.local))."
    }
}
$UpdateButton.Add_Click({
    $u = $script:PendingUpdate
    if (-not $u) { return }
    $ok = [System.Windows.MessageBox]::Show($window, "Install version $($u.latest)? Your parked saves and settings are kept. The launcher restarts afterwards.", 'NBA 2K17 Launcher', 'YesNo', 'Question')
    if ($ok -ne 'Yes') { return }
    $UpdateButton.IsEnabled = $false
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $window.Dispatcher.Invoke([Action] {}, [System.Windows.Threading.DispatcherPriority]::Render)
    try {
        [void](Invoke-Update $u.url $u.latest)
        [System.Windows.MessageBox]::Show($window, "Updated to version $($u.latest). The launcher will now restart.", 'NBA 2K17 Launcher', 'OK', 'Information') | Out-Null
        $t = Get-LauncherShortcutTarget
        if ($t.args) { Start-Process $t.target -ArgumentList $t.args -WorkingDirectory $t.workdir } else { Start-Process $t.target -WorkingDirectory $t.workdir }
        $window.Close()
    } catch {
        $msg = $_.Exception.Message -replace '^SWITCHER: ', ''
        Append-Log $msg 'ERROR'
        [System.Windows.MessageBox]::Show($window, "The update did not finish: $msg", 'NBA 2K17 Launcher', 'OK', 'Warning') | Out-Null
        $UpdateButton.IsEnabled = $true
    } finally {
        $window.Cursor = $null
    }
})

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(4)
$timer.Add_Tick({ Refresh-View; Poll-UpdateCheck })
$window.Add_Loaded({
    Start-Float $BallBounce -10 0.55
    Start-Float $Bubble1Move -22 5.5
    Start-Float $Bubble2Move 18 4.2
    Start-Float $Bubble3Move -16 6.3
    Start-Float $Bubble4Move 14 3.6
    Append-Log "Welcome back. Saves vault: $script:AppDir"
    Refresh-View
    if (-not (Load-State)) { Run-Setup }
    Start-UpdateCheck
    $timer.Start()
})
$window.Add_Closed({ $timer.Stop() })
[void]$window.ShowDialog()
