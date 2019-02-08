for %%G in (*.sql) do sqlcmd /S S26 /d DNB -E -i"%%G"
pause