Add-Type -AssemblyName System.Drawing

$raiz = Split-Path $PSScriptRoot -Parent
$entrada = Join-Path $raiz "resultados\parte5_curva_limiar.csv"
$saida = Join-Path $raiz "resultados\parte5_grafico_limiar.png"
$inv = [Globalization.CultureInfo]::InvariantCulture
$br = [Globalization.CultureInfo]::GetCultureInfo("pt-BR")

$series = @{}
foreach ($linha in (Import-Csv $entrada)) {
    if (-not $series.ContainsKey($linha.modo)) { $series[$linha.modo] = @() }
    $series[$linha.modo] += [pscustomobject]@{
        X = [double]::Parse($linha.limiar, $inv)
        Y = [double]::Parse($linha.mediana_s, $inv)
    }
}

$todos = @($series.Values | ForEach-Object { $_ })
$maximo = ($todos | Measure-Object -Property Y -Maximum).Maximum
$yMax = [Math]::Ceiling($maximo * 5) / 5
$xMax = 256.0

$largura = 1000
$altura = 600
$esq = 90
$dir = 50
$topo = 80
$base = 100
$areaL = $largura - $esq - $dir
$areaA = $altura - $topo - $base

function PX([double]$x) { return [single]($esq + $x / $xMax * $areaL) }
function PY([double]$y) { return [single]($topo + $areaA - $y / $yMax * $areaA) }

$bmp = New-Object System.Drawing.Bitmap $largura, $altura
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear([System.Drawing.Color]::White)

$fonteTitulo = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fonteEixo = New-Object System.Drawing.Font("Segoe UI", 12)
$fonteTick = New-Object System.Drawing.Font("Segoe UI", 10)
$fontePonto = New-Object System.Drawing.Font("Segoe UI", 9)
$preto = [System.Drawing.Brushes]::Black
$cinza = [System.Drawing.Brushes]::DimGray
$penGrade = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(225, 225, 225)), 1
$penEixo = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 2
$centro = New-Object System.Drawing.StringFormat
$centro.Alignment = [System.Drawing.StringAlignment]::Center
$direita = New-Object System.Drawing.StringFormat
$direita.Alignment = [System.Drawing.StringAlignment]::Far

$g.DrawString("Tempo × LIMIAR (branch.c, -O1, 10.000 repetições)", $fonteTitulo, $preto, [single]($largura / 2), 18, $centro)

for ($y = 0.0; $y -le $yMax + 0.0001; $y += 0.2) {
    $g.DrawLine($penGrade, (PX 0), (PY $y), (PX $xMax), (PY $y))
    $g.DrawString($y.ToString("0.0", $br), $fonteTick, $cinza, [single]($esq - 8), [single]((PY $y) - 9), $direita)
}

$ticks = @(0, 32, 64, 96, 128, 160, 192, 224, 250, 256)
foreach ($x in $ticks) {
    $g.DrawLine($penGrade, (PX $x), (PY 0), (PX $x), (PY $yMax))
    $descida = if ($x -eq 250) { 26 } else { 8 }
    $g.DrawString([string]$x, $fonteTick, $cinza, (PX $x), [single]((PY 0) + $descida), $centro)
}

$g.DrawLine($penEixo, (PX 0), (PY 0), (PX $xMax), (PY 0))
$g.DrawLine($penEixo, (PX 0), (PY 0), (PX 0), (PY $yMax))
$g.DrawString("LIMIAR", $fonteEixo, $preto, [single]($esq + $areaL / 2), [single]($altura - 45), $centro)

$estado = $g.Save()
$g.TranslateTransform(22, [single]($topo + $areaA / 2))
$g.RotateTransform(-90)
$g.DrawString("Tempo (s) — mediana de 5 execuções", $fonteEixo, $preto, 0, 0, $centro)
$g.Restore($estado)

$estilos = @(
    @{ Modo = "aleatorio"; Rotulo = "Array aleatório"; Cor = [System.Drawing.Color]::FromArgb(31, 119, 180); Rotular = $true },
    @{ Modo = "sort";      Rotulo = "Array ordenado";  Cor = [System.Drawing.Color]::FromArgb(230, 120, 20); Rotular = $false }
)

$legendaX = (PX 150)
$legendaY = $topo + 8
foreach ($e in $estilos) {
    if (-not $series.ContainsKey($e.Modo)) { continue }
    $pontos = @($series[$e.Modo] | Sort-Object X)
    $pen = New-Object System.Drawing.Pen $e.Cor, 3
    $pincel = New-Object System.Drawing.SolidBrush $e.Cor
    $coords = [System.Drawing.PointF[]]@($pontos | ForEach-Object { New-Object System.Drawing.PointF (PX $_.X), (PY $_.Y) })
    $g.DrawLines($pen, $coords)
    foreach ($p in $pontos) {
        $g.FillEllipse($pincel, [single]((PX $p.X) - 5), [single]((PY $p.Y) - 5), 10, 10)
        if ($e.Rotular) {
            $deslocX = if ($p.X -eq 0) { 16 } else { 0 }
            $g.DrawString($p.Y.ToString("0.00", $br), $fontePonto, $preto, [single]((PX $p.X) + $deslocX), [single]((PY $p.Y) - 24), $centro)
        }
    }
    $g.DrawLine($pen, [single]$legendaX, [single]($legendaY + 9), [single]($legendaX + 30), [single]($legendaY + 9))
    $g.FillEllipse($pincel, [single]($legendaX + 10), [single]($legendaY + 4), 10, 10)
    $g.DrawString($e.Rotulo, $fonteTick, $preto, [single]($legendaX + 38), [single]$legendaY)
    $legendaY += 22
}

$bmp.Save($saida, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Output $saida
