param(
  [string]$OutputPath = (Join-Path $env:USERPROFILE "Pictures\matrix-wallpaper.png"),
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
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$rand = New-Object System.Random

function New-BinaryString {
  param(
    [int]$Length,
    [double]$SpaceProbability = 0.12
  )

  $sb = New-Object System.Text.StringBuilder
  for ($i = 0; $i -lt $Length; $i++) {
    if ($rand.NextDouble() -lt $SpaceProbability) {
      [void]$sb.Append(' ')
    } else {
      if ($rand.Next(0, 2) -eq 0) { [void]$sb.Append('0') } else { [void]$sb.Append('1') }
    }
  }
  return $sb.ToString()
}

$fontName = "Consolas"
if (-not ([System.Drawing.FontFamily]::Families | Where-Object { $_.Name -eq $fontName })) {
  $fontName = "Lucida Console"
}

$fontCache = @{}
function Get-Font {
  param([int]$Size)
  if (-not $fontCache.ContainsKey($Size)) {
    $fontCache[$Size] = New-Object System.Drawing.Font($fontName, $Size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  }
  return $fontCache[$Size]
}

$rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $rect,
  [System.Drawing.Color]::FromArgb(255, 1, 10, 2),
  [System.Drawing.Color]::FromArgb(255, 0, 0, 0),
  90.0
)
$g.FillRectangle($bg, $rect)
$bg.Dispose()

# Soft center glow.
for ($i = 0; $i -lt 12; $i++) {
  $alpha = [int](28 - ($i * 2))
  if ($alpha -lt 0) { $alpha = 0 }
  $size = [int]($Width * (0.30 + ($i * 0.10)))
  $xGlow = [int](($Width * 0.50) - ($size / 2))
  $yGlow = [int](($Height * 0.52) - ($size / 2))
  $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 8, 130, 25))
  $g.FillEllipse($glowBrush, $xGlow, $yGlow, $size, $size)
  $glowBrush.Dispose()
}

# Scanlines for CRT feel.
$scanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(16, 24, 145, 40), 1)
for ($y = 0; $y -lt $Height; $y += 3) {
  $g.DrawLine($scanPen, 0, $y, $Width, $y)
}
$scanPen.Dispose()

# Binary floor lines for depth.
$floorTop = [int]($Height * 0.67)
for ($row = 0; $row -lt 26; $row++) {
  $t = $row / 25.0
  $y = [int]($floorTop + ([Math]::Pow($t, 1.65) * ($Height - $floorTop)))
  $fontSize = [int](8 + ($t * 11))
  $font = Get-Font $fontSize
  $alpha = [int](15 + ($t * 55))
  if ($alpha -gt 95) { $alpha = 95 }
  $line = New-BinaryString -Length ([int](130 + ($t * 220))) -SpaceProbability (0.08 + ((1 - $t) * 0.18))
  $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 18, 165, 45))
  $xStart = -[int]($Width * 0.16) + $rand.Next(-120, 61)

  for ($rep = 0; $rep -lt 3; $rep++) {
    $xRep = $xStart + ($rep * [int]($Width * 0.55))
    $g.DrawString($line, $font, $brush, [float]$xRep, [float]$y)
  }

  $brush.Dispose()
}

# Distant rain layer (smaller and dimmer).
$x = -6
while ($x -lt ($Width + 10)) {
  $fontSize = $rand.Next(10, 15)
  $font = Get-Font $fontSize
  $step = [Math]::Max(10, [int]($fontSize * 0.9))
  $trailLength = $rand.Next(24, 62)
  $headY = $rand.Next(-280, $Height + 260)
  $jitter = $rand.Next(-2, 3)

  for ($i = 0; $i -lt $trailLength; $i++) {
    if ($rand.NextDouble() -lt 0.12) { continue }
    $y = [int]($headY - ($i * ($fontSize - 1)))
    if ($y -lt -$fontSize -or $y -gt ($Height + $fontSize)) { continue }

    $bit = if ($rand.Next(0, 2) -eq 0) { '0' } else { '1' }
    $alpha = [int](120 - ($i * (95 / [Math]::Max($trailLength, 1))))
    if ($alpha -lt 18) { $alpha = 18 }
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 20, 145, 42))
    $g.DrawString($bit, $font, $brush, [float]($x + $jitter), [float]$y)
    $brush.Dispose()
  }

  $x += $step
}

# Foreground rain layer (larger, brighter, high contrast).
$x2 = -8
while ($x2 -lt ($Width + 12)) {
  $fontSize = $rand.Next(17, 31)
  $font = Get-Font $fontSize
  $step = [Math]::Max(13, [int]($fontSize * 0.72))
  $trailLength = $rand.Next(14, 42)
  $headY = $rand.Next(-220, $Height + 320)
  $jitter = $rand.Next(-3, 4)

  for ($i = 0; $i -lt $trailLength; $i++) {
    if ($rand.NextDouble() -lt 0.08) { continue }
    $y = [int]($headY - ($i * ($fontSize - 2)))
    if ($y -lt -$fontSize -or $y -gt ($Height + $fontSize)) { continue }

    $bit = if ($rand.Next(0, 2) -eq 0) { '0' } else { '1' }

    if ($i -eq 0) {
      $glow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 165, 255, 185))
      $g.FillEllipse($glow, $x2 + $jitter - [int]($fontSize * 0.26), $y - [int]($fontSize * 0.15), [int]($fontSize * 0.95), [int]($fontSize * 0.95))
      $glow.Dispose()

      $headBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 228, 255, 236))
      $g.DrawString($bit, $font, $headBrush, [float]($x2 + $jitter), [float]$y)
      $headBrush.Dispose()

      $streakPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(64, 120, 255, 150), 2)
      $g.DrawLine($streakPen, $x2 + $jitter + [int]($fontSize * 0.18), $y + $fontSize, $x2 + $jitter + [int]($fontSize * 0.18), $y + [int]($fontSize * 2.2))
      $streakPen.Dispose()
    } elseif ($i -le 2) {
      $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(225, 118, 255, 145))
      $g.DrawString($bit, $font, $brush, [float]($x2 + $jitter), [float]$y)
      $brush.Dispose()
    } else {
      $alpha = [int](205 - ($i * (175 / [Math]::Max($trailLength, 1))))
      if ($alpha -lt 25) { $alpha = 25 }
      $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 28, 215, 62))
      $g.DrawString($bit, $font, $brush, [float]($x2 + $jitter), [float]$y)
      $brush.Dispose()
    }
  }

  $x2 += $step
}

# Subtle noise points to avoid flat areas.
for ($n = 0; $n -lt 1800; $n++) {
  $nx = $rand.Next(0, $Width)
  $ny = $rand.Next(0, $Height)
  $a = $rand.Next(6, 28)
  $dot = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($a, 20, 170, 45))
  $g.FillRectangle($dot, $nx, $ny, 1, 1)
  $dot.Dispose()
}

# Edge vignette for cinematic contrast.
for ($i = 0; $i -lt 22; $i++) {
  $alpha = [int](8 + ($i * 4))
  if ($alpha -gt 110) { $alpha = 110 }
  $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 0, 0, 0), 2)
  $g.DrawRectangle($pen, $i, $i, $Width - (2 * $i) - 1, $Height - (2 * $i) - 1)
  $pen.Dispose()
}

$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

foreach ($kv in $fontCache.GetEnumerator()) {
  $kv.Value.Dispose()
}

$g.Dispose()
$bmp.Dispose()

if ($Apply) {
  Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"
  Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"

  if (-not ("NativeWallpaper" -as [type])) {
    Add-Type @"
using System.Runtime.InteropServices;
public class NativeWallpaper {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
  }

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
