void Menu::watermark()
{
    if (!g_Options.misc.misc_watermark)
        return;

    auto t = std::time(nullptr);
    std::ostringstream time;
    time << std::put_time(std::localtime(&t), "%H:%M:%S");

    std::string Cheatname = ("Sunshine.space");

    auto watermark = Cheatname + (" | ") + comp_name() + (" | ") + time.str();

    if (g_EngineClient->IsInGame())
    {

        auto nci = g_EngineClient->GetNetChannelInfo();

        auto net_channel = g_EngineClient->GetNetChannelInfo();

        auto local_player = reinterpret_cast<C_BasePlayer*>(g_EntityList->GetClientEntity(g_EngineClient->GetLocalPlayer()));
        std::string outgoing = local_player ? std::to_string((int)(net_channel->GetLatency(FLOW_OUTGOING) * 1000)) : "0";


        if (nci)
        {
            auto server = nci->GetAddress();

            if (!strcmp(server, ("loopback")))
                server = ("local server");
            else
                server = ("valve server");

            auto tickrate = std::to_string((int)(1.0f / g_GlobalVars->interval_per_tick));

            watermark = Cheatname + (" | ") + comp_name() + (" | ") + server + (" | delay: ") + outgoing.c_str() + (" ms | ") + tickrate + (" tick | ") + time.str();
        }
    }
    ImVec2 p, s;
    ImGui::PushFont(g_SpectatorListFont);
    auto size_text = ImGui::CalcTextSize(watermark.c_str());
    ImGui::PopFont();
    ImGui::SetNextWindowSize(ImVec2(size_text.x + (Menu::Get().IsVisible() ? 24 : 14), 20));

    ImGui::Begin("watermark", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_::ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_::ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_::ImGuiWindowFlags_NoNavFocus | ImGuiWindowFlags_::ImGuiWindowFlags_NoNav);
    {
        auto d = ImGui::GetWindowDrawList();
        p = ImGui::GetWindowPos();
        s = ImGui::GetWindowSize();
        ImGui::PushFont(g_SpectatorListFont);
        ImGui::SetWindowSize(ImVec2(s.x, 21 + 18));
        //
        d->AddRectFilled(p, p + ImVec2(s.x, 21), ImColor(39, 39, 39, int(50 * 1)));
        auto main_colf = ImColor(39, 39, 39, int(255 * 1));
        auto main_coll = ImColor(39, 39, 39, int(140 * 1));
        d->AddRectFilledMultiColor(p, p + ImVec2(s.x / 2, 20), main_coll, main_colf, main_colf, main_coll);
        d->AddRectFilledMultiColor(p + ImVec2(s.x / 2, 0), p + ImVec2(s.x, 20), main_colf, main_coll, main_coll, main_colf);
        //
        auto main_colf2 = ImColor(39, 39, 39, int(255 * min(1 * 2, 1.f)));
        d->AddRectFilledMultiColor(p, p + ImVec2(s.x / 2, 20), main_coll, main_colf2, main_colf2, main_coll);
        d->AddRectFilledMultiColor(p + ImVec2(s.x / 2, 0), p + ImVec2(s.x, 20), main_colf2, main_coll, main_coll, main_colf2);
        auto line_colf = ImColor(126, 131, 219, 200);
        auto line_coll = ImColor(126, 131, 219, 255);
        d->AddRectFilledMultiColor(p, p + ImVec2(s.x / 2, 2), line_coll, line_colf, line_colf, line_coll);
        d->AddRectFilledMultiColor(p + ImVec2(s.x / 2, 0), p + ImVec2(s.x, 2), line_colf, line_coll, line_coll, line_colf);
        d->AddText(p + ImVec2((Menu::Get().IsVisible() ? s.x - 10 : s.x) / 2 - size_text.x / 2, (20) / 2 - size_text.y / 2), ImColor(250, 250, 250, int(230 * min(1 * 3, 1.f))), watermark.c_str());
    }
    ImGui::End();
}