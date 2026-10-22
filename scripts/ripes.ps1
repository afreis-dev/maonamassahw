param(
    [string]$Ripes = "Ripes.exe",
    [int]$EsperaMs = 15000
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path $PSScriptRoot -Parent
$saida = Join-Path $raiz "resultados\ripes"
New-Item -ItemType Directory -Force -Path $saida | Out-Null

$processadores = @(
    @{ Nome = "5s";           Proc = "RV32_5S";          TemHz = $true },
    @{ Nome = "5s_sem_fw";    Proc = "RV32_5S_NO_FW";    TemHz = $true },
    @{ Nome = "5s_sem_hz";    Proc = "RV32_5S_NO_HZ";    TemHz = $false },
    @{ Nome = "5s_sem_fw_hz"; Proc = "RV32_5S_NO_FW_HZ"; TemHz = $false }
)

$dados = @(
    @{ Nome = "aleatorio"; Fonte = "laco.s";          FonteComNops = "laco_sem_hz.s" },
    @{ Nome = "ordenado";  Fonte = "laco_ordenado.s"; FonteComNops = "laco_sem_hz_ordenado.s" }
)

function Invoke-Ripes([string]$fonte, [string]$proc, [string]$destino, [switch]$Json) {
    if (Test-Path $destino) { Remove-Item $destino }
    $argumentos = @("--mode", "cli", "--src", "`"$fonte`"", "-t", "asm", "--proc", $proc, "--all", "--output", "`"$destino`"")
    if ($Json) { $argumentos += "--json" }
    $p = Start-Process -FilePath $Ripes -ArgumentList $argumentos -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit($EsperaMs)) {
        $p.Kill()
        $p.WaitForExit()
        return $false
    }
    return (Test-Path $destino)
}

function Invoke-Relatorio([string]$fonte, [string]$proc, [string]$base) {
    $terminou = Invoke-Ripes $fonte $proc "$base.txt"
    if ($terminou) {
        Invoke-Ripes $fonte $proc "$base.json" -Json | Out-Null
        Write-Output ("{0,-18} {1,-34} terminou" -f $proc, (Split-Path $fonte -Leaf))
    } else {
        Set-Content -Path "$base.nao_termina.txt" -Value "Ripes nao terminou em $EsperaMs ms: $proc com $(Split-Path $fonte -Leaf)" -Encoding ascii
        Write-Output ("{0,-18} {1,-34} NAO TERMINA" -f $proc, (Split-Path $fonte -Leaf))
    }
}

foreach ($d in $dados) {
    foreach ($p in $processadores) {
        $base = Join-Path $saida ("{0}_{1}" -f $p.Nome, $d.Nome)
        Invoke-Relatorio (Join-Path $raiz ("ripes\" + $d.Fonte)) $p.Proc $base
        if (-not $p.TemHz) {
            Invoke-Relatorio (Join-Path $raiz ("ripes\" + $d.FonteComNops)) $p.Proc "${base}_com_nops"
        }
    }
}
