import SwiftUI

struct ContentView: View {
    
    var body: some View {
        
        ZStack {
            
            Color.standardColor
                .ignoresSafeArea()
            
            mainAppView()
            
            .padding()
            
        }
        
    }
    
};

extension Color {
    
    static let textStandardColor = Color(red: 0/255, green: 0/255, blue: 0/255);
    static let standardColor = Color(red: 250/255, green: 250/255, blue: 255/255);
    static let secondaryColor = Color(red: 14/255, green: 110/255, blue: 124/255);
    static let standardDarkerColor = Color(red: 71/255, green: 194/255, blue: 203/255);
    
}

#Preview {
    ContentView()
}
