﻿using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Items.Components;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MoonSharp.Interpreter;

[assembly: IgnoresAccessChecksTo("Barotrauma")]
namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        public readonly Dictionary<string, UIStyleProcessor> Styles = new();
        public UIStyleProcessor? DefaultStyles => Styles.ContainsKey("default") ? Styles["default"] : null;

        void LoadStylesFiles(ContentPackage package, ContentPath filelist)
        {
            XDocument doc = XMLExtensions.TryLoadXml(filelist);
            if (doc is null)
                return;
            var element = doc.Root?.FromPackage(package);
            if (element is null)
                return;
            foreach (ContentXElement styleElement in element.GetChildElements("Other"))
            {
                string stylesTypeCheck = styleElement.GetAttributeString("type", string.Empty);
                if (stylesTypeCheck != "styles")    // we cannot add custom node names to filelist.xml or it throws an error.
                    continue;
                string styleFilepath = styleElement.GetAttributeString("file", string.Empty);
                string name = styleElement.GetAttributeString("name", string.Empty);
                if (styleFilepath == string.Empty || name == string.Empty)
                    continue;
                if (Styles.ContainsKey(name))
                    throw new ArgumentException(
                        $"A style file with the name of {name} already exists in the dictionary!");
                var xpath = ContentPath.FromRaw(package, styleFilepath);
                var styleP = new UIStyleProcessor(package, xpath);
                styleP.LoadFile();
                Styles[name] = styleP;
            }
        }
        
        void ClientInitialize()
        {
            UserData.RegisterType<UIStyleProcessor>();
            changeConnectionGUI();
            LoadStylesFiles(SelfPackage, ContentPath.FromRaw(SelfPackage, System.IO.Path.Combine(SelfPackage.Dir, "filelist.xml")));
        }
        
        // Change the connection gui to show the steam and kinetic networks
        private void changeConnectionGUI()
        {
            // Override the DrawConnection function for connections
            // Most of the code is the same as the original just an extra if statements for colour picking
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Connection",
                typeof(Connection).GetMethod("DrawConnection", BindingFlags.Instance | BindingFlags.NonPublic),
                (Object self, Dictionary<string, object> args) => {
                    // Assign parameters and helper variables for ease of use
                    Connection myself = (Connection)self;

                    SpriteBatch spriteBatch = (SpriteBatch)args["spriteBatch"];
                    ConnectionPanel panel = (ConnectionPanel)args["panel"];
                    Vector2 position = (Vector2)args["position"];
                    Vector2 labelPos = (Vector2)args["labelPos"];
                    Vector2 scale = (Vector2)args["scale"];

                    // get connection text
                    string text = myself.DisplayName.Value.ToUpperInvariant();

                    //nasty -- original comment
                    if (GUIStyle.GetComponentStyle("ConnectionPanelLabel")?.Sprites.Values.First().First() is UISprite labelSprite)
                    {
                        // Calculate an appropriate label size for the text
                        Vector2 textSize = GUIStyle.SmallFont.MeasureString(text);
                        Rectangle labelArea = new Rectangle(labelPos.ToPoint(), textSize.ToPoint());
                        labelArea.Inflate(10 * scale.X, 3 * scale.Y);

                        // Set background colour based on the grid type
                        Color colour = Color.SteelBlue;
                        if (myself.IsPower)
                        {
                            colour = GUIStyle.Red;
                            if (myself.Name.StartsWith("steam"))
                            {
                                colour = Color.DeepSkyBlue;
                            }
                            else if (myself.Name.StartsWith("kinetic"))
                            {
                                colour = Color.SaddleBrown;
                            }
                            else if (myself.Name.StartsWith("thermal"))
                            {
                                colour = Color.Orange;
                            }
                            else if (myself.Name.StartsWith("water"))
                            {
                                colour = Color.DodgerBlue;
                            }
                        }

                        labelSprite.Draw(spriteBatch, labelArea, colour);
                    }

                    // Draw text with an outline
                    GUI.DrawString(spriteBatch, labelPos + Vector2.UnitY, text, Color.Black * 0.8f, font: GUIStyle.SmallFont);
                    GUI.DrawString(spriteBatch, labelPos, text, GUIStyle.TextColorBright, font: GUIStyle.SmallFont);

                    // Draw the connection sprite
                    float connectorSpriteScale = (35.0f / Connection.connectionSprite.SourceRect.Width) * panel.Item.Scale;
                    Connection.connectionSprite.Draw(spriteBatch, position, scale: connectorSpriteScale);

                    // Prevent the original method from running
                    return true;
                }, LuaCsHook.HookMethodType.Before);
        }
    }
}
