$content = Get-Content docs/diagrama-arquitectura-propuesto.md -Raw
$content = $content -replace '- Pendiente: Route 53, AWS WAF, listener HTTPS con ACM.', '- Pendiente: AWS WAF, listener HTTPS (sin Route 53).'
$content = $content -replace '- Route 53 \(DNS\): Traduce el nombre de dominio a la infraestructura de AWS.', ''
Set-Content docs/diagrama-arquitectura-propuesto.md -Value $content

$content = Get-Content docs/infraestructura.md -Raw
$content = $content -replace '- Route 53 \(registro alias al ALB\).', ''
$content = $content -replace 'Cliente\(\[fa:fa-laptop Cliente Web\]\) -- "HTTPS:443" --> R53\[1\. Route 53\]', 'Cliente([fa:fa-laptop Cliente Web]) -- "HTTPS:443" --> WAF[1. AWS WAF]'
$content = $content -replace 'L1 ~~~ R53', 'L1 ~~~ WAF'
$content = $content -replace 'R53 --> WAF', 'WAF --> ALB'
Set-Content docs/infraestructura.md -Value $content
