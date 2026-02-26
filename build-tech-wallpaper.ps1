param(
  [string]$OutputPath = (Join-Path $env:USERPROFILE "Pictures\\tech-wallpaper.png"),
  [int]$Width = 0,
  [int]$Height = 0,
  [switch]$Apply = $true
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

if ($Width -le 0 -or $Height -le 0) {
  $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $Width = $bounds.Width
  $Height = $bounds.Height
}

$outDir = Split-Path -Path $OutputPath -Parent
if ($outDir -and -not (Test-Path $outDir)) {
  New-Item -Path $outDir -ItemType Directory -Force | Out-Null
}

$bmp = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $rect,
  [System.Drawing.Color]::FromArgb(255, 6, 12, 24),
  [System.Drawing.Color]::FromArgb(255, 0, 0, 0),
  35.0
)
$g.FillRectangle($bgBrush, $rect)
$bgBrush.Dispose()

# Ambient neon glow.
for ($i = 0; $i -lt 9; $i++) {
  $alpha = [int](70 - ($i * 7))
  if ($alpha -lt 0) { $alpha = 0 }
  $size = [int]($Width * (0.20 + ($i * 0.08)))
  $x = [int]($Width * 0.68) - [int]($size / 2)
  $y = [int]($Height * 0.28) - [int]($size / 2)
  $glow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 210, 255))
  $g.FillEllipse($glow, $x, $y, $size, $size)
  $glow.Dispose()
}

$horizonY = [int]($Height * 0.60)
$vanishX = [int]($Width * 0.50)

# Perspective grid.
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(45, 0, 200, 255), 1)
for ($x = -$Width; $x -le ($Width * 2); $x += 80) {
  $g.DrawLine($gridPen, $x, $Height, $vanishX, $horizonY)
}
for ($i = 0; $i -le 22; $i++) {
  $t = $i / 22.0
  $y = [int]($horizonY + (($t * $t) * ($Height - $horizonY)))
  $g.DrawLine($gridPen, 0, $y, $Width, $y)
}
$gridPen.Dispose()

$horizonPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 0, 240, 255), 2)
$g.DrawLine($horizonPen, 0, $horizonY, $Width, $horizonY)
$horizonPen.Dispose()

# Circuit traces and nodes.
$rand = New-Object System.Random
$tracePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(130, 0, 220, 255), 2)
$tracePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$tracePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

for ($t = 0; $t -lt 140; $t++) {
  $x = $rand.Next(0, $Width)
  $y = $rand.Next([int]($Height * 0.08), [int]($Height * 0.95))
  $segments = $rand.Next(3, 8)

  for ($s = 0; $s -lt $segments; $s++) {
    $dir = $rand.Next(0, 4)
    $len = $rand.Next(35, 170)
    $nx = $x
    $ny = $y

    switch ($dir) {
      0 { $nx = [Math]::Min($Width - 1, $x + $len) }
      1 { $nx = [Math]::Max(0, $x - $len) }
      2 { $ny = [Math]::Min($Height - 1, $y + $len) }
      3 { $ny = [Math]::Max(0, $y - $len) }
    }

    $g.DrawLine($tracePen, $x, $y, $nx, $ny)

    if ($rand.NextDouble() -lt 0.30) {
      $nodeSize = $rand.Next(3, 8)
      $nodeCore = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 120, 255, 255))
      $nodeGlow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 230, 255))
      $g.FillEllipse($nodeGlow, $nx - ($nodeSize * 2), $ny - ($nodeSize * 2), $nodeSize * 4, $nodeSize * 4)
      $g.FillEllipse($nodeCore, $nx - [int]($nodeSize / 2), $ny - [int]($nodeSize / 2), $nodeSize, $nodeSize)
      $nodeCore.Dispose()
      $nodeGlow.Dispose()
    }

    $x = $nx
    $y = $ny
  }
}
$tracePen.Dispose()

# Hex-like overlays for a technical HUD feel.
$hexPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(55, 0, 255, 220), 1)
for ($i = 0; $i -lt 26; $i++) {
  $cx = $rand.Next(0, $Width)
  $cy = $rand.Next(0, $Height)
  $r = $rand.Next(22, 70)
  $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
  for ($k = 0; $k -lt 6; $k++) {
    $a = ($k * 60.0) * [Math]::PI / 180.0
    $px = $cx + ($r * [Math]::Cos($a))
    $py = $cy + ($r * [Math]::Sin($a))
    $pts.Add([System.Drawing.PointF]::new([float]$px, [float]$py))
  }
  $g.DrawPolygon($hexPen, $pts.ToArray())
}
$hexPen.Dispose()

# Subtle scanlines.
$scanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(18, 0, 255, 255), 1)
for ($y = 0; $y -lt $Height; $y += 4) {
  $g.DrawLine($scanPen, 0, $y, $Width, $y)
}
$scanPen.Dispose()

$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

if ($Apply) {
  Set-ItemProperty -Path "HKCU:\\Control Panel\\Desktop" -Name WallpaperStyle -Value "10"
  Set-ItemProperty -Path "HKCU:\\Control Panel\\Desktop" -Name TileWallpaper -Value "0"

  Add-Type @"
using System.Runtime.InteropServices;
public class NativeWallpaper {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

  $SPI_SETDESKWALLPAPER = 20
  $SPIF_UPDATEINIFILE = 0x01
  $SPIF_SENDWININICHANGE = 0x02
  [void][NativeWallpaper]::SystemParametersInfo(
    $SPI_SETDESKWALLPAPER,
    0,
    $OutputPath,
    $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE
  )
}

Write-Output "Wallpaper generated: $OutputPath ($Width x $Height)"
