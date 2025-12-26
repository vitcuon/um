    void SetUpColors()
    {
        ImGuiStyle& style = ImGui::GetStyle();
        style.WindowMinSize = ImVec2(600, 350);

        style.Colors[ImGuiCol_WindowBg] = ImColor(25, 20, 20);
        style.Colors[ImGuiCol_ChildBg] = ImColor(30, 24, 24);
        style.Colors[ImGuiCol_Text] = ImColor(255, 255, 255);
        //Header
        style.Colors[ImGuiCol_Header] = ImColor(30, 200, 100);
        style.Colors[ImGuiCol_HeaderHovered] = ImColor(40, 215, 96);
        style.Colors[ImGuiCol_HeaderActive] = ImColor(30, 215, 96);
        //buttons
        style.Colors[ImGuiCol_Button] = ImColor(25, 215, 96);
        style.Colors[ImGuiCol_ButtonHovered] = ImColor(40, 215, 96);
        style.Colors[ImGuiCol_ButtonActive] = ImColor(30, 190, 96);
        //checkboxes
        style.Colors[ImGuiCol_CheckMark] = ImColor(0, 0, 0);
        style.Colors[ImGuiCol_FrameBg] = ImColor(25, 215, 96, 240);
        style.Colors[ImGuiCol_FrameBgActive] = ImColor(25, 215, 96);
        style.Colors[ImGuiCol_FrameBgHovered] = ImColor(20, 250, 90);
    }

