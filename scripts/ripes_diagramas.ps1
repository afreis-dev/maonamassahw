Add-Type -AssemblyName System.Drawing

$raiz = Split-Path $PSScriptRoot -Parent
$pasta = Join-Path $raiz "resultados\ripes"
$destino = Join-Path $pasta "prints"
New-Item -ItemType Directory -Force -Path $destino | Out-Null

$json = Get-Content (Join-Path $pasta "5s_aleatorio.json") -Raw | ConvertFrom-Json
$linhas = @($json.pipeline -split "`n" | Where-Object { $_.Trim() -ne "" })
$totalCiclos = $json.cycles

$instrucoes = @()
for ($i = 1; $i -lt $linhas.Count; $i++) {
    $partes = $linhas[$i] -split "`t"
    $tokens = @()
    for ($c = 0; $c -le $totalCiclos; $c++) {
        $indice = $c + 1
        $tokens += $(if ($indice -lt $partes.Count) { $partes[$indice] } else { "" })
    }
    $execucoes = @()
    $atual = $null
    for ($c = 0; $c -le $totalCiclos; $c++) {
        $t = $tokens[$c]
        if ($t -eq "IF") {
            if ($atual) { $execucoes += , $atual }
            $atual = [pscustomobject]@{ Inicio = $c; Fim = $c; Estagios = @("IF"); TemEX = $false }
        } elseif ($t -ne "" -and $atual) {
            $atual.Fim = $c
            $atual.Estagios += $t
            if ($t -eq "EX") { $atual.TemEX = $true }
        } elseif ($t -eq "" -and $atual) {
            $execucoes += , $atual
            $atual = $null
        }
    }
    if ($atual) { $execucoes += , $atual }
    $instrucoes += [pscustomobject]@{ Rotulo = $partes[0]; Tokens = $tokens; Execucoes = $execucoes }
}

$cores = @{
    "IF"  = [System.Drawing.Color]::FromArgb(255, 205, 210)
    "ID"  = [System.Drawing.Color]::FromArgb(255, 236, 179)
    "EX"  = [System.Drawing.Color]::FromArgb(200, 230, 201)
    "MEM" = [System.Drawing.Color]::FromArgb(179, 229, 252)
    "WB"  = [System.Drawing.Color]::FromArgb(225, 190, 231)
    "-"   = [System.Drawing.Color]::FromArgb(158, 158, 158)
}

function Get-Execucao($instrucao, $cicloInicio) {
    foreach ($e in $instrucao.Execucoes) { if ($e.Inicio -eq $cicloInicio) { return $e } }
    return $null
}

$legendas = New-Object System.Collections.Generic.List[string]

function New-Diagrama([string]$titulo, [int]$c0, [int]$c1, [string]$legenda, [string]$arquivo) {
    $legendas.Add("$titulo`r`n$legenda`r`n")
    $visiveis = @($instrucoes | Where-Object {
        $linha = $_
        $achou = $false
        for ($c = $c0; $c -le $c1; $c++) { if ($linha.Tokens[$c] -ne "") { $achou = $true; break } }
        $achou
    })
    $larguraRotulo = 230
    $celulaL = 54
    $celulaA = 28
    $topo = 70
    $colunas = $c1 - $c0 + 1
    $largura = $larguraRotulo + $colunas * $celulaL + 30
    $altura = $topo + $celulaA * ($visiveis.Count + 1) + 90
    $bmp = New-Object System.Drawing.Bitmap $largura, $altura
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)
    $fTitulo = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $fTexto = New-Object System.Drawing.Font("Consolas", 10)
    $fCelula = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $fLegenda = New-Object System.Drawing.Font("Segoe UI", 10)
    $preto = [System.Drawing.Brushes]::Black
    $borda = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 120, 120)), 1
    $bordaFlush = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(198, 40, 40)), 2
    $centro = New-Object System.Drawing.StringFormat
    $centro.Alignment = [System.Drawing.StringAlignment]::Center
    $centro.LineAlignment = [System.Drawing.StringAlignment]::Center

    $g.DrawString($titulo, $fTitulo, $preto, 10, 10)
    for ($c = $c0; $c -le $c1; $c++) {
        $x = $larguraRotulo + ($c - $c0) * $celulaL
        $g.DrawString([string]$c, $fCelula, $preto, [System.Drawing.RectangleF]::new($x, $topo, $celulaL, $celulaA), $centro)
    }
    $g.DrawString("ciclo", $fCelula, $preto, [System.Drawing.RectangleF]::new(10, $topo, $larguraRotulo - 20, $celulaA), (New-Object System.Drawing.StringFormat))

    $linhaIndice = 1
    foreach ($ins in $visiveis) {
        $y = $topo + $linhaIndice * $celulaA
        $g.DrawString($ins.Rotulo, $fTexto, $preto, 10, [single]($y + 5))
        for ($c = $c0; $c -le $c1; $c++) {
            $t = $ins.Tokens[$c]
            if ($t -eq "") { continue }
            $x = $larguraRotulo + ($c - $c0) * $celulaL
            $retangulo = New-Object System.Drawing.Rectangle $x, $y, $celulaL, $celulaA
            $descartada = $false
            foreach ($e in $ins.Execucoes) {
                if ($c -ge $e.Inicio -and $c -le $e.Fim -and -not $e.TemEX) { $descartada = $true }
            }
            $cor = $cores[$t]
            if ($descartada) { $cor = [System.Drawing.Color]::FromArgb(224, 224, 224) }
            $pincel = New-Object System.Drawing.SolidBrush $cor
            $g.FillRectangle($pincel, $retangulo)
            $g.DrawRectangle($(if ($descartada) { $bordaFlush } else { $borda }), $retangulo)
            $texto = $(if ($t -eq "-") { "parada" } else { $t })
            $g.DrawString($texto, $fCelula, $(if ($t -eq "-") { [System.Drawing.Brushes]::White } else { $preto }), [System.Drawing.RectangleF]::new($x, $y, $celulaL, $celulaA), $centro)
        }
        $linhaIndice++
    }

    $yLegenda = $topo + ($visiveis.Count + 1) * $celulaA + 14
    $g.DrawString($legenda, $fLegenda, $preto, [System.Drawing.RectangleF]::new(10, $yLegenda, $largura - 20, 70))
    $bmp.Save($arquivo, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Output $arquivo
}

$cicloPrimeiroPreenchido = -1
for ($c = 0; $c -le $totalCiclos; $c++) {
    $ocupados = @("IF", "ID", "EX", "MEM", "WB" | Where-Object { $estagio = $_; @($instrucoes | Where-Object { $_.Tokens[$c] -eq $estagio }).Count -gt 0 })
    if ($ocupados.Count -eq 5) { $cicloPrimeiroPreenchido = $c; break }
}
New-Diagrama "(a) Pipeline enchendo - RV32 5-stage, laco.s" 0 9 "Os 5 estagios ficam ocupados pela primeira vez no ciclo $cicloPrimeiroPreenchido. Antes disso o pipeline esta enchendo." (Join-Path $destino "a_pipeline_enchendo.png")

$lw = $instrucoes | Where-Object { $_.Rotulo -like "lw *" } | Select-Object -First 1
$bltDado = $instrucoes | Where-Object { $_.Rotulo -like "blt x5 *" } | Select-Object -First 1
$lwExecucao = $lw.Execucoes[0]
$bltExecucao = $bltDado.Execucoes[0]
$cicloBolha = -1
for ($c = $bltExecucao.Inicio; $c -le $bltExecucao.Fim; $c++) { if ($bltDado.Tokens[$c] -eq "-") { $cicloBolha = $c; break } }
New-Diagrama "(b) Bolha por load-use - lw x5 seguido de blt x5" $lwExecucao.Inicio ($lwExecucao.Inicio + 9) "O blt precisa de x5, que o lw so entrega depois de MEM. No ciclo $cicloBolha o blt fica parado em ID (e o add em IF): entra uma bolha (nop) em EX e o blt so executa um ciclo depois, ja com x5 via forwarding." (Join-Path $destino "b_bolha_load_use.png")

$bltLaco = $instrucoes | Where-Object { $_.Rotulo -like "blt x12 *" } | Select-Object -First 1
$bltTomado = $bltLaco.Execucoes[0]
$cicloEX = -1
for ($c = $bltTomado.Inicio; $c -le $bltTomado.Fim; $c++) { if ($bltLaco.Tokens[$c] -eq "EX" -and $cicloEX -lt 0) { $cicloEX = $c } }
$listaDescartadas = @()
foreach ($ins in $instrucoes) {
    foreach ($x in $ins.Execucoes) {
        if (-not $x.TemEX -and $x.Inicio -gt $bltTomado.Inicio -and $x.Inicio -le $cicloEX) { $listaDescartadas += $ins.Rotulo }
    }
}
New-Diagrama "(c) Flush no desvio tomado - blt x12, x11, laco" ($bltTomado.Inicio - 3) ($bltTomado.Inicio + 9) "O blt e decidido em EX (ciclo $cicloEX). As $($listaDescartadas.Count) instrucoes que ja tinham entrado no pipeline atras dele ($($listaDescartadas -join '; ')) sao descartadas (cinza com borda vermelha) e nunca chegam a EX. O PC volta para laco." (Join-Path $destino "c_flush_desvio.png")
Set-Content -Path (Join-Path $destino "legendas.txt") -Value ($legendas -join "`r`n") -Encoding utf8
