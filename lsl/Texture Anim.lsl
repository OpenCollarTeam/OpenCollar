default
{
    state_entry()
    {
        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, ALL_SIDES, 200, 10, 0, 0, 50.0);
    }
    
    on_rez(integer param)
    {
        llResetScript();
    }
}
