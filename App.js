import { useState } from "react";
import { Pressable, SafeAreaView, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { StatusBar } from "expo-status-bar";
import { analyzeMessage, samples } from "./src/analyze";

const tabs = [
  { id: "inbox", label: "Фон" },
  { id: "check", label: "Текст" },
  { id: "fake", label: "AI Analyze" },
];

export default function App() {
  const [tab, setTab] = useState("inbox");
  const [armed, setArmed] = useState(true);
  const [blocked, setBlocked] = useState(false);
  const [text, setText] = useState(samples[0].text);
  const result = analyzeMessage(text);

  return (
    <SafeAreaView style={styles.safe}>
      <StatusBar style="dark" />
      <ScrollView contentContainerStyle={styles.page}>
        <Text style={styles.mark}>Qorğan</Text>
        <Text style={styles.lead}>Фон, проверка сообщений и дипфейк в одном приложении.</Text>

        {tab === "inbox" && (
          <View>
            <Text style={styles.h2}>Фоновое приложение</Text>
            <Text style={styles.p}>
              Пока защита включена, сообщение со срочностью, кодом или чужой ссылкой уходит в блок само.
            </Text>
            <Pressable style={styles.solid} onPress={() => setArmed((value) => !value)}>
              <Text style={styles.solidText}>{armed ? "Фон включён" : "Фон выключен"}</Text>
            </Pressable>
            <Pressable
              style={styles.ghost}
              onPress={() => setBlocked(true)}
            >
              <Text style={styles.ghostText}>Симулировать входящее</Text>
            </Pressable>
            <View style={[styles.card, blocked && armed ? styles.blocked : null]}>
              <Text style={styles.cardTitle}>
                {!blocked ? "Ждём сообщение" : armed ? "В блоке" : "Пропущено: фон был выключен"}
              </Text>
              <Text style={styles.p}>
                {blocked
                  ? samples[0].text
                  : "Приложение стоит в фоне и смотрит входящие тексты."}
              </Text>
            </View>
          </View>
        )}

        {tab === "check" && (
          <View>
            <Text style={styles.h2}>Детектор сообщений</Text>
            <View style={styles.row}>
              {samples.map((sample) => (
                <Pressable key={sample.id} style={styles.ghost} onPress={() => setText(sample.text)}>
                  <Text style={styles.ghostText}>{sample.label}</Text>
                </Pressable>
              ))}
            </View>
            <TextInput
              multiline
              value={text}
              onChangeText={setText}
              style={styles.input}
            />
            <View style={[styles.card, result.verdict === "block" ? styles.blocked : styles.ok]}>
              <Text style={styles.cardTitle}>
                {result.verdict === "block" ? "В блок" : "Можно пропустить"} · {result.score}
              </Text>
              {result.reasons.map((reason) => (
                <Text key={reason} style={styles.p}>{reason}</Text>
              ))}
            </View>
            <Text style={styles.note}>Правило-прототип. Модель обучим следующим шагом.</Text>
          </View>
        )}

        {tab === "fake" && (
          <View>
            <Text style={styles.h2}>AI Analyze</Text>
            <Text style={styles.p}>
              Модуль научного руководителя внутри Qorğan. Он будет проверять видео и голос: живой человек это или дипфейк в звонке «из банка».
            </Text>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Модель ещё не подключена</Text>
              <Text style={styles.p}>
                Экран уже стоит в приложении. Вердикт не показываем, пока модель не обучена, чтобы не выдавать ложный результат.
              </Text>
            </View>
          </View>
        )}
      </ScrollView>

      <View style={styles.tabs}>
        {tabs.map((item) => (
          <Pressable key={item.id} style={styles.tab} onPress={() => setTab(item.id)}>
            <Text style={[styles.tabText, tab === item.id && styles.tabOn]}>{item.label}</Text>
          </Pressable>
        ))}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#f3efe6" },
  page: { padding: 20, paddingBottom: 32 },
  mark: { fontSize: 42, fontWeight: "700", color: "#172028" },
  lead: { color: "#5c675f", fontSize: 16, lineHeight: 22, marginBottom: 18 },
  h2: { fontSize: 26, fontWeight: "700", marginBottom: 8, color: "#172028" },
  p: { color: "#3d4742", fontSize: 16, lineHeight: 22, marginBottom: 8 },
  note: { color: "#5c675f", marginTop: 8 },
  row: { flexDirection: "row", gap: 8, marginBottom: 10 },
  solid: { backgroundColor: "#0b3d31", borderRadius: 999, paddingVertical: 12, paddingHorizontal: 16, alignSelf: "flex-start", marginVertical: 8 },
  solidText: { color: "#fff", fontWeight: "700" },
  ghost: { borderColor: "#0b3d31", borderWidth: 1, borderRadius: 999, paddingVertical: 10, paddingHorizontal: 14, alignSelf: "flex-start", marginRight: 8, marginBottom: 8 },
  ghostText: { color: "#0b3d31", fontWeight: "700" },
  input: { minHeight: 120, borderWidth: 1, borderColor: "#ddd4c4", borderRadius: 14, padding: 12, backgroundColor: "#fff", textAlignVertical: "top", marginBottom: 12 },
  card: { backgroundColor: "#fffdf8", borderRadius: 16, padding: 14, borderWidth: 1, borderColor: "#ddd4c4", marginTop: 8 },
  blocked: { backgroundColor: "#f8e8e4", borderColor: "#e3c2bc" },
  ok: { backgroundColor: "#e5f3ec", borderColor: "#b7d8c8" },
  cardTitle: { fontSize: 18, fontWeight: "700", marginBottom: 6, color: "#172028" },
  tabs: { flexDirection: "row", borderTopWidth: 1, borderTopColor: "#ddd4c4", backgroundColor: "#fffdf8" },
  tab: { flex: 1, paddingVertical: 14, alignItems: "center" },
  tabText: { color: "#5c675f", fontWeight: "700" },
  tabOn: { color: "#0e6b52" },
});
