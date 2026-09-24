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
    
    static let textStandardColor = Color(red: 37/255, green: 99/255, blue: 235/255);
    static let standardColor = Color(red: 7/255, green: 234/255, blue: 254/255);
    static let secondaryColor = Color(red: 147/255, green: 197/255, blue: 7/255);
    static let standardDarkerColor = Color(red: 219/255, green: 7/255, blue: 254/255);
    
}

#Preview {
    ContentView()
}
