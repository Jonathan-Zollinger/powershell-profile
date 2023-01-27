Add-Type -AssemblyName System.Speech
$SpeechSynthesizer = New-Object -TypeName System.Speech.Syntesis.SpeechSynthesizer
Set-Alias -Name 'spd-say' -Value $SpeechSynthesizer