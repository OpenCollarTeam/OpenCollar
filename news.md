# OpenCollar 3.7 is here! - 20111017.1

Hi all.  A few things to know about this update

1. There is no more web database.  Unfortunately the price of our hosting is 
going up more than we can manage right now.  I've written [an FAQ] [1] giving
more details.

2. OpenCollar is now modular.  You only have to run the scripts you need, so
you can save lag on the sims you visit.  If you run the updater and find you're
missing a feature that you used to have, you just need to run it again and make
sure you select that bundle.

3. There's currently a [bug] (https://jira.secondlife.com/browse/SVC-7321) in
LL's code that prevents some full perms items from transferring cleanly with
llGiveInventory and llRemoteLoadScriptPin.  You might see errors relating to
this on update.  There is supposed to be a fix currently in the regions on the
"Magnum" release channel.  


Thank you!

Nirea and Athaliah

[1]: https://github.com/nirea/ocupdater/blob/master/docs/FAQ%20on%20OpenCollar%20Database%20Retirement.md 
