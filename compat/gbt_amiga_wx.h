/* What Gambit's GUI takes from wxWidgets that the GFOpenWX Toolkit does not
 * have yet, forced in ahead of each src/gui source (-include). Each piece
 * goes away by itself once the toolkit has the real one.
 *   wxCommandLinkButton (the welcome window's three big buttons): a plain
 *     wxButton with the main label, the note as its tool tip.
 *   wxDROP_ICON (the drag cursor in the game tree): no cursor of its own.
 * Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit. */
#ifndef GBT_AMIGA_WX_H
#define GBT_AMIGA_WX_H

#ifdef __cplusplus
#include <wx/defs.h>
#include <wx/button.h>
#include <wx/cursor.h>

#if !wxUSE_COMMANDLINKBUTTON
class wxCommandLinkButton : public wxButton
{
public:
    wxCommandLinkButton() = default;
    wxCommandLinkButton( wxWindow *p_parent, wxWindowID p_id, const wxString &p_mainLabel = wxString(),
                         const wxString &p_note = wxString(), const wxPoint &p_pos = wxDefaultPosition,
                         const wxSize &p_size = wxDefaultSize, long p_style = 0,
                         const wxValidator &p_validator = wxDefaultValidator,
                         const wxString &p_name = wxButtonNameStr )
        : wxButton( p_parent, p_id, p_mainLabel, p_pos, p_size, p_style, p_validator, p_name )
    {
        SetNote( p_note );
    }
    void SetMainLabel( const wxString &p_label ) { SetLabel( p_label ); }
    void SetNote( const wxString &p_note )
    {
        m_note = p_note;
        if( !p_note.empty() )
            SetToolTip( p_note );
    }
    wxString GetMainLabel() const { return GetLabel(); }
    wxString GetNote() const { return m_note; }

private:
    wxString m_note;
};
#endif

#ifndef wxDROP_ICON
#define wxDROP_ICON( name ) wxNullCursor
#endif
#endif

#endif
